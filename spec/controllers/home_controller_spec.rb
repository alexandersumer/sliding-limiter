# spec/controllers/home_controller_spec.rb

class MockHomeController < ActionController::Base
	before_action :rate_limit
	
	include RateLimiter

	def rate_limit
		rate_limiter_client = RateLimiter::Client.new(3, 10, request.ip)
		if rate_limiter_client.is_blocked?
			render status: TOO_MANY_REQUESTS, plain: rate_limiter_client.blocked_message
		else
			rate_limiter_client.increment
		end
	end

	def index
		render status: OK, plain: "You are welcome!"
	end
end

RSpec.describe MockHomeController, type: :controller do
	before do
		Rails.application.routes.draw { get 'index' => 'mock_home#index' }
	end

	describe 'limit requestor' do
		it 'block requestor if more than 3 requests within 10 seconds' do
			get :index
			expect(response.status).to eq OK
			expect(response.body).to eq "You are welcome!"

			get :index
			expect(response.status).to eq OK
			expect(response.body).to eq "You are welcome!"

			get :index
			expect(response.status).to eq OK
			expect(response.body).to eq "You are welcome!"

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS
			expect(response.body).to eq "Rate limit exceeded. Try again in 10 seconds"
		end
	end
end
