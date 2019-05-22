# spec/controllers/home_controller_spec.rb

class MockHomeController < ActionController::Base
	before_action :rate_limit
	
	include RateLimiter

	def rate_limit
		threshold = 3
		interval = 3
		accuracy = 4 # if you lower accuracy, not all the tests will pass

		limiter = RateLimiter::LimiterClient.new("key", threshold, interval, accuracy)
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

RSpec.describe MockHomeController, type: :controller do
	before do
		Rails.application.routes.draw { get "index" => "mock_home#index" }
	end

	describe "home_controller" do
		it "Spam pattern" do
			$redis.flushdb
			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS
		end

		it "One request per second pattern" do
			$redis.flushdb

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS

			sleep(1)

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS
			
			sleep(1)

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS
		end

		it "Two one zero two one 429 pattern" do
			$redis.flushdb

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			sleep(2)

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq OK

			sleep(1)

			get :index
			expect(response.status).to eq OK

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS
			
			sleep(1)

			get :index
			expect(response.status).to eq TOO_MANY_REQUESTS
		end
	end
end
