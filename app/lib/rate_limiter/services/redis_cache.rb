# app/lib/rate_limiter/services/redis_cache.rb

module RateLimiter
	class RedisCache
		def initialize
			@redis = $redis
		end

		def increment(key, bucket)
			@redis.HINCRBY(key, bucket, 1)
		end

		def get_keys(key)
			return @redis.HKEYS(key).map { |x| x.to_i }
		end

		def get_values(key)
			return @redis.HVALS(key).map { |x| x.to_i }
		end

		def delete(key, to_delete)
			@redis.HDEL(key, to_delete)
		end
		
		def flush
			@redis.flushdb
		end
	end
end