# app/lib/rate_limiter/services/limiter.rb

require_relative 'cache'

module RateLimiter
	class Limiter
		attr_reader :requests, :period, :requestor_id, :cache

		def initialize(requests, period, requestor_id, cache_client)
			@requests = requests
			@period = period
			@requestor_id = requestor_id
			@cache = Cache.new(cache_client)
		end

		def is_blocked?
			if cache.get_count(blocked_requestor_key)
				return true
			else
				return false
			end
		end

		def increment
			count = cache.get_count(allowed_requestor_key)
			cache.initialize_requestor(allowed_requestor_key, 1, period) unless count
			if count.to_i >= requests
				cache.block_requestor(blocked_requestor_key, period)
			else
				cache.increment_count(allowed_requestor_key)
			end
		end

		def blocked_message
			cooldown = cache.get_cooldown(blocked_requestor_key)
			"Rate limit exceeded. Try again in #{cooldown} seconds"
		end

		def allowed_requestor_key
			return "allowed_requestor_#{requestor_id}"
		end

		def blocked_requestor_key
			return "blocked_requestor_#{requestor_id}"
		end
	end
end