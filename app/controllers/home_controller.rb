# app/controllers/home_controller.rb

class HomeController < ActionController::Base
	before_action :rate_limit

	include RateLimiter

	def rate_limit
		rate_limiter_client = RateLimiter::Client.new(request.ip)
		if rate_limiter_client.is_blocked?
			render status: TOO_MANY_REQUESTS, plain: rate_limiter_client.blocked_message
		else
			rate_limiter_client.increment
		end
	end

	def index
		render plain: 'You are welcome!'
	end
end
