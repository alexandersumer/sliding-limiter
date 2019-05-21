# app/lib/rate_limiter/limiter_client.rb

require_relative './services/limiter'
require_relative './services/redis_cache'
require_relative './services/local_mem_cache'

module RateLimiter
	class LimiterClient
		def initialize(key, requestor_id, threshold, interval, accuracy = 4)
			local_mem_cache = LocalMemoryCache.new
			redis_cache = RedisCache.new
			@limiter = RateLimiter::Limiter.new(key, threshold, interval, accuracy, redis_cache)
		end

		def is_blocked?(requestor_id)
			@limiter.is_blocked?(requestor_id)
		end

		def increment(requestor_id)
			@limiter.increment(requestor_id)
		end

		def get_error_message(requestor_id)
			@limiter.get_error_message(requestor_id)
		end
	end
end