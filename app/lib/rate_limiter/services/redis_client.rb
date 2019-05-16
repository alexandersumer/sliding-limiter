# app/lib/rate_limiter/services/redis_client.rb

module RateLimiter
	class RedisClient
		attr_reader :cache
		
		def initialize
			@cache = $redis
		end

		def get(key)
			cache.get(key)
		end

		def set(key, value, period)
			cache.set(key, value)
			cache.expire(key, period)
		end

		def incr(key)
			cache.incr(key)
		end

		def ttl(key)
			cache.ttl(key)
		end
	end
end