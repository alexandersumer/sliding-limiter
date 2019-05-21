# app/lib/rate_limiter/services/local_mem_cache.rb

require_relative "./registry"
require_relative "./cache_interface"

module RateLimiter
	class LocalMemCache < Cache
		def initialize
			@registry = Registry.instance
		end

		def increment(parent_key, child_key)
			buckets = @registry.get(parent_key)
			
			if !buckets
				@registry.set(parent_key, {})
				buckets = @registry.get(parent_key)
			end

			if !buckets[child_key]
				buckets[child_key] = 1
			else
				buckets[child_key] = buckets[child_key] + 1
			end
		end

		def get_keys(parent_key)
			buckets = @registry.get(parent_key)
			return buckets.keys.map { |x| x.to_i } if buckets
            []
		end

		def get_values(parent_key)
			buckets = @registry.get(parent_key)
			return buckets.values.map { |x| x.to_i } if buckets
			[]
		end

		def delete(parent_key, to_delete)
			to_delete
			buckets = @registry.get(parent_key)
			to_delete.each { |x| buckets.delete(x) }
		end
		
		def flush
			@registry.clear
		end
	end
end