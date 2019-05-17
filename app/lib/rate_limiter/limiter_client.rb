# app/lib/rate_limiter/limiter_client.rb

require_relative './services/limiter'
require_relative './services/redis_client'

module RateLimiter
	class LimiterClient
		attr_reader :limiter

		def initialize(requests, period, requestor_id, cache_client = RedisClient.new)
			@limiter = RateLimiter::Limiter.new(requests, period, requestor_id, cache_client)
		end

		def is_blocked?
			limiter.is_blocked?
		end

		def increment
			limiter.increment
		end

		def blocked_message
			limiter.blocked_message
		end
	end
end