# app/lib/rate_limiter/services/redis_client.rb

module RateLimiter
	class RedisClient
		attr_reader :redis
		
		def initialize
			@redis = $redis
		end

		def get(key)
			redis.get(key)
		end

		def set(key, value, period)
			redis.set(key, value)
			redis.expire(key, period)
		end

		def incr(key)
			redis.incr(key)
		end

		def ttl(key)
			redis.ttl(key)
		end
		
		def flushdb
			redis.flushdb
		end
	end
end