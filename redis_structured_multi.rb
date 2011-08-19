require 'fmap'
require 'redis'

class Redis
  class ReceiptedPipeline < Pipeline
    class Receipt
      def initialize(pipeline, token, commands = nil)
        @pipeline = pipeline
        @token = token
        @commands = (commands or [])
      end

      def ===( o )
        if o.kind_of? Thunk
          @pipeline.equal?(o.pipeline)
        else
          super
        end
      end
      
      def method_missing(m, *args, &bl)
        new_command = [m, args, bl]
        self.class.new(@pipeline, @token, @commands + [new_command])
      end
    end
    
    class Thunk
      def initialize(pipeline, mbulk_reply)
        @pipeline = pipeline
        @mbulk_reply = mbulk_reply
        @evaled_receipts = {}
      end
      
      attr :pipeline

      def ===( o )
        if o.kind_of? Receipt
          @pipeline.equal?(o.pipeline)
        else
          super
        end
      end
      
      def []( receipt )
        receipt_token = receipt.instance_variable_get(:@token)
        return @evaled_receipts[receipt_token] if @evaled_receipts.has_key?( receipt_token )
        
        response = @mbulk_reply[ receipt_token ]
        receipt.instance_variable_get(:@commands).inject(response) do |o, (m, args, bl)|
          evaled_args = args.eqfmap(self){ |receipt| self[ receipt ] }
          o.send(m, *evaled_args, &bl)
        end
      end
    end


    def initialize
      super
      @tokens_generated = 0
    end
    
    def generate_reply_receipt
      token = (@tokens_generated += 1) - 1
      Receipt.new( self, token )
    end

    def call(*args)
      super
      self.generate_reply_receipt
    end
    
    def call_pipelined(commands, options = {})
      before = @commands.length
      super
      after = @commands.length
      
      receipts = []
      (after - before).times { receipts << self.generate_reply_receipt }
      receipts
    end
  end

  def pipelined_with_receipts(options = {})
    synchronize do
      begin
        original, @client = @client, ReceiptedPipeline.new
        yield

        unless @client.commands.empty?
          receipted_pipeline = @client
          pipeline_reply = original.call_pipelined(@client.commands, options)
          mbulk_reply = pipeline_reply.last
          ReceiptedPipeline::Thunk.new(receipted_pipeline, mbulk_reply)
        end
      ensure
        @client = original
      end
    end
  end
  
  def structured_multi
    synchronize do
      structure = nil
      pipeline_thunk = pipelined_with_receipts(:raise => false) do
        @client.call_without_reply([:multi])
        structure = yield(self)
        @client.call_without_reply([:exec])
      end

      structure.eqfmap(pipeline_thunk){ |receipt| pipeline_thunk[ receipt ] }
    end
  end
end