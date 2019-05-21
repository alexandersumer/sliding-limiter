# app/lib/rate_limiter/services/redis_cache.rb

require_relative "./cache_interface"

module RateLimiter
	class RedisCache < Cache
		def initialize
			@redis = $redis
		end

		def increment(requestor_key, timestamp)
			@redis.HINCRBY(requestor_key, timestamp, 1)
		end

		def get_keys(requestor_key)
			return @redis.HKEYS(requestor_key).map { |x| x.to_i }
		end

		def get_values(requestor_key)
			return @redis.HVALS(requestor_key).map { |x| x.to_i }
		end

		def delete(requestor_key, entries_to_delete)
			@redis.HDEL(requestor_key, entries_to_delete)
		end
		
		def flush
			@redis.flushdb
		end
	end
end