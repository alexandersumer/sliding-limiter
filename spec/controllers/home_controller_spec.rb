# spec/controllers/home_controller_spec.rb

class MockHomeController < ActionController::Base
	before_action :rate_limit
	
	include RateLimiter

	def rate_limit
		threshold = 3
		interval = 3
		accuracy = 4 # if you lower accurate, not all the tests will pass
		redis_cache = RedisCache.new
		local_mem_cache = LocalMemCache.new
		limiter = RateLimiter::LimiterClient.new(
			"key", threshold, interval, accuracy, redis_cache
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

RSpec.describe MockHomeController, type: :controller do
	before do
		Rails.application.routes.draw { get 'index' => 'mock_home#index' }
	end

	describe 'rate_limit' do
		it 'block requestor if more than 3 requests within 3 seconds' do\
			# Scenario 1: 3 x OK then 3 x TOO_MANY_REQUESTS consecutively
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

			puts "(CONTROLLER TEST) Scenario: Spam pattern | *PASSED*"

			sleep(3)

			# Scenario 2: 1 x OK every second, 1 x TOO_MANY_REQUESTS on every 3rd second

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

			puts "(CONTROLLER TEST) Scenario: One request per second pattern | *PASSED*"

			sleep(2)

			# Scenario 3:	second 1 => 2 x OK
			#				second 2 => 1 x OK
			#				second 3 => 0
			#				second 4 => 2 x OK
			#				second 5 => 1 x OK and 1 x TOO_MANY_REQUESTS

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

			puts "(CONTROLLER TEST) Scenario: Two one zero two one 429 pattern | *PASSED*"
		end
	end
end
