# spec/lib/rate_limiter/mock_redis_cache.rb

require 'mock_redis'

module RateLimiter
	class RedisCache
		attr_reader :container
		
		def initialize(container = MockRedis.new)
			@container = container
		end

		def get(key)
			container.get(key)
		end

		def set(key, value, max_period)
			container.set(key, value)
			container.expire(key, max_period)
		end

		def incr(key)
			container.incr(key)
		end

		def ttl(key)
			container.ttl(key)
		end
	end
end