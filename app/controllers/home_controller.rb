# app/controllers/home_controller.rb

class HomeController < ActionController::Base
	before_action :rate_limit

	include RateLimiter

	def rate_limit
		limiter = RateLimiter::LimiterClient.new("unique_id", request.ip, THRESHOLD, INTERVAL)
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
