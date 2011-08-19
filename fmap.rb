class Object
  module Composite
    def fmap(&bl)
      begin
        new_inst = self.clone
      rescue TypeError
        return self
      end

      new_inst.instance_variables.each do |iv_name|
        iv_val = new_inst.instance_variable_get(iv_name)
        fmapped_val = bl.call( iv_val.fmap(&bl) )
        new_inst.instance_variable_set(iv_name, fmapped_val)
      end
    end
    
    def fmap_composite?
      true
    end
  end

  def fmap_composite?
    false
  end

  def fmap
    yield( self )
  end

  def afmap
    self.fmap{ |v| v.fmap_composite? ? v : yield(v) }
  end
  
  def eqfmap(type)
    self.fmap{ |v| (v === type) ? yield(v) : v }
  end
end

module Enumerable
  def fmap_composite?
    true
  end
  
  def fmap(&bl)
    bl.call( self.map{ |v| v.fmap(&bl) } )
  end
end

class Range
  def fmap(&bl)
    bl.call( self.class.new(
      self.first.fmap(&bl),
      self.last.fmap(&bl),
      self.exclude_end?) )
  end
end

class Hash
  def fmap(&bl)
    new_h = self.class.new
    self.each do |k, v|
      new_h[k.fmap(&bl)] = v.fmap(&bl)
    end
    bl.call( new_h )
  end
end

class Set
  def fmap(&bl)
    bl.call( self.map{ |v| v.fmap(&bl) }.to_set )
  end
end