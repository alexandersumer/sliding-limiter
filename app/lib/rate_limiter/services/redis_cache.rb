# app/lib/rate_limiter/services/redis_cache.rb

module RateLimiter
	class RedisCache
		def initialize
			@redis = $redis
		end

		def increment(parent_key, child_key)
			@redis.HINCRBY(parent_key, child_key, 1)
		end

		def get_keys(parent_key)
			return @redis.HKEYS(parent_key).map { |x| x.to_i }
		end

		def get_values(parent_key)
			return @redis.HVALS(parent_key).map { |x| x.to_i }
		end

		def delete(parent_key, entries_to_delete)
			@redis.HDEL(parent_key, entries_to_delete)
		end
		
		def flush
			@redis.flushdb
		end
	end
end