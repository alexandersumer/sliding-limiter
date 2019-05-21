# app/lib/rate_limiter/services/local_mem_cache.rb

require_relative "./registry"
require_relative "./cache_interface"

module RateLimiter
	class LocalMemCache < Cache
		def initialize
			@registry = Registry.instance
		end

		def increment(requestor_key, timestamp)
			buckets = @registry.get(requestor_key)
			
			if !buckets
				@registry.set(requestor_key, {})
				buckets = @registry.get(requestor_key)
			end

			if !buckets[timestamp]
				buckets[timestamp] = 1
			else
				buckets[timestamp] = buckets[timestamp] + 1
			end
		end

		def get_keys(requestor_key)
			buckets = @registry.get(requestor_key)
			return buckets.keys.map { |x| x.to_i } if buckets
            []
		end

		def get_values(requestor_key)
			buckets = @registry.get(requestor_key)
			return buckets.values.map { |x| x.to_i } if buckets
			[]
		end

		def delete(requestor_key, to_delete)
			to_delete
			buckets = @registry.get(requestor_key)
			to_delete.each { |x| buckets.delete(x) }
		end
		
		def flush
			@registry.clear
		end
	end
end