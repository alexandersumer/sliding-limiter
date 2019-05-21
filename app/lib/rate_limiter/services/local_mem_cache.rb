# app/lib/rate_limiter/services/local_mem_cache.rb

require_relative "./registry"

module RateLimiter
	class LocalMemoryCache
		def initialize
			@registry = Registry.instance
		end

		def increment(key, bucket)
			buckets = @registry.get(key)
			
			if !buckets
				@registry.set(key, {})
				buckets = @registry.get(key)
			end

			if !buckets[bucket]
				buckets[bucket] = 1
			else
				buckets[bucket] = buckets[bucket] + 1
			end
		end

		def get_keys(key)
			buckets = @registry.get(key)
			return buckets.keys.map { |x| x.to_i } if buckets
            []
		end

		def get_values(key)
			buckets = @registry.get(key)
			return buckets.values.map { |x| x.to_i } if buckets
			[]
		end

		def delete(key, to_delete)
			to_delete
			buckets = @registry.get(key)
			to_delete.each { |x| buckets.delete(x) }
		end
		
		def flush
			@registry.clear
		end
	end
end