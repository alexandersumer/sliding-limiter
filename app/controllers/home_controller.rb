# app/controllers/home_controller.rb

require_relative '../lib/rate_limiter/services/redis_cache'
require_relative '../lib/rate_limiter/services/local_mem_cache'
require_relative '../lib/rate_limiter/services/cache_client'

class HomeController < ActionController::Base
	before_action :rate_limit

	include RateLimiter

	def rate_limit
		threshold = THRESHOLD
		interval = INTERVAL
		accuracy = ACCURACY
		redis_cache = RedisCache.new
		local_mem_cache = LocalMemCache.new

		limiter = RateLimiter::LimiterClient.new(
			"handle_authentication_requests", threshold, interval, accuracy, CacheClient.new(redis_cache)
		)

		if limiter.is_blocked?(request.ip)
			render status: TOO_MANY_REQUESTS, plain: limiter.get_error_message(request.ip)
		else
			limiter.increment(request.ip)
		end
	end

	def index
		render status: OK, plain: "You are welcome!"
	end
end
