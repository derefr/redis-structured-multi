`redis-structured-multi` is a Ruby library for assembling Redis's multibulk replies (from the [redis-rb gem](https://github.com/ezmobius/redis-rb)'s `Redis#multi`) into objects, before they're actually returned, by using futures, thunks, and a Ruby implementation of `fmap`.

Just require `redis_structured_multi`, then you can do something like this:

    records = [
      {:name => 'bob', :height => 180, :likes => 'carrots'},
      {:name => 'phil', :height => 145, :likes => 'apples'}]

    REDIS = Redis.new

    full_records = REDIS.structured_multi do
      records.map do |record|
        interests = (REDIS.smembers("user:#{record[:name]}:smembers") + [record[:likes]]).to_set
        last_visit = REDIS.get("user:#{record[:name]}:lastvisittime").to_i
        
        left_handed = REDIS.get("user:#{record[:name]}:has:hand:left")
        right_handed = REDIS.get("user:#{record[:name]}:has:hand:right")
        record.merge(
          :interests => interests,
          :last_visit => last_visit,
          :has_both_hands => (left_handed && right_handed))
      end
    end

Under the covers, this is a single Redis pipeline. Even though we're able to do things like `left_handed && right_handed`, or `set_members + other_set_members`, we're really just transforming promises into other promises. Here's the strategy:

1. Execute a bunch of redis commands; receive promises in exchange.
2. Build the structure you want out of data you have, plus these promises.
3. Return this structure as the value of the `structured_multi` block.

After you do this, `structured-multi` will actually execute the pipeline, then `fmap` your structure into an equivalent one with all the same real data, but with the promises replaced with their actual Redis-retrieved values.
