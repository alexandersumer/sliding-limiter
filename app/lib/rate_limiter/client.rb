# app/lib/rate_limiter/client.rb

module RateLimiter
	class Client
		attr_reader :limiter

		def initialize(requestor_id)
			@limiter = RateLimiter::Limiter.new(
				max_requests = MAX_REQUESTS,
				max_period = MAX_PERIOD,
				cache = Cache.new,
				requestor_id = requestor_id
			)
		end

		def is_blocked?
			if limiter.is_blocked?
				return true
			else
				return false
			end
		end

		def increment
			limiter.increment
		end

		def blocked_message
			limiter.blocked_message
		end
	end
end