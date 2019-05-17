# spec/controllers/home_controller_spec.rb

class MockHomeController < ActionController::Base
	before_action :rate_limit
	
	include RateLimiter

	def rate_limit
		limiter_client = RateLimiter::LimiterClient.new(3, 10, request.ip)
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
