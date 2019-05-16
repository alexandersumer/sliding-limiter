# app/lib/rate_limiter/limiter.rb

module RateLimiter
	class Limiter
		attr_reader :max_requests, :max_period, :cache, :requestor_id

		def initialize(max_requests, max_period, cache, requestor_id)
			@max_requests = max_requests
			@max_period = max_period
			@cache = cache
			@requestor_id = requestor_id
		end

		def blocked_message
			"Rate limit exceeded. Try again in #{ttl(blocked_requestor_key)} seconds"
		end

		def allowed_requestor_key
			return "allowed_requestor_#{requestor_id}"
		end

		def blocked_requestor_key
			return "blocked_requestor_#{requestor_id}"
		end

		def is_blocked?
			if get_count(blocked_requestor_key)
				return true
			else
				return false
			end
		end

		def increment
			count = get_count(allowed_requestor_key)
			if !count
				set(allowed_requestor_key, 1)
			elsif count.to_i >= max_requests
				block_requestor(blocked_requestor_key)
			else
				incr(allowed_requestor_key)
			end
		end

		def block_requestor(key)
			cache.set(key, 1, max_period)
		end

		def get_count(key)
			cache.get(key)
		end

		def set(key, value)
			cache.set(key, value, max_period)
		end

		def incr(key)
			cache.incr(key)
		end

		def ttl(key)
			cache.ttl(key)
		end
	end
end