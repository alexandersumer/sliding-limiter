# spec/lib/rate_limiter/mock_redis_cache.rb

require 'mock_redis'

module RateLimiter
	class RedisCache
		attr_reader :cache
		
		def initialize(cache = MockRedis.new)
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