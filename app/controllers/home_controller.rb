# app/controllers/home_controller.rb

class HomeController < ActionController::Base
	before_action :rate_limit

	include RateLimiter

	def rate_limit
		limiter_client = RateLimiter::LimiterClient.new(REQUESTS, PERIOD, request.ip)
		if limiter_client.is_blocked?
			render status: TOO_MANY_REQUESTS, plain: limiter_client.blocked_message
		else
			limiter_client.increment
		end
	end

	def index
		render status: OK, plain: "You are welcome!"
	end
end
