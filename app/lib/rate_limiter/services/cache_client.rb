# app/lib/rate_limiter/services/cache_client.rb

require_relative "./cache_interface"

module RateLimiter

	# This class is a client that hides the underlying implementation of the cache

	class CacheClient < Cache
		def initialize(cache = RedisCache.new)
			@cache = cache
		end

		def increment(requestor_key, timestamp)
			@cache.increment(requestor_key, timestamp)
		end

		def get_keys(requestor_key)
			return @cache.get_keys(requestor_key)
		end

		def get_values(requestor_key)
			return @cache.get_values(requestor_key)
		end

		def delete(requestor_key, entries_to_delete)
			@cache.delete(requestor_key, entries_to_delete)
		end
		
		def flush
			@cache.flush
		end
	end
end