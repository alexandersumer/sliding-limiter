# app/lib/rate_limiter/redis_cache.rb

module RateLimiter
	class RedisCache
		attr_reader :cache
		
		def initialize(cache = $redis)
			@cache = cache
		end

		def get(key)
			cache.get(key)
		end

		def set(key, value, max_period)
			cache.set(key, value)
			cache.expire(key, max_period)
		end

		def incr(key)
			cache.incr(key)
		end

		def ttl(key)
			cache.ttl(key)
		end
	end
end