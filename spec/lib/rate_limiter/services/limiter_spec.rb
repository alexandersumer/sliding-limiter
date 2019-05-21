# spec/lib/rate_limiter/services/limiter_spec.rb

RSpec.describe RateLimiter::Limiter do
    subject { described_class }
    let(:limiter) { described_class.new("unique_id", 3, 3, 4) }

    describe "#is_blocked?" do
        it "Increments requestor 3 times, should become blocked" do
            $redis.flushdb
            limiter.increment("0.0.0.0")
            limiter.increment("0.0.0.0")
            limiter.increment("0.0.0.0")
            expect(limiter.is_blocked?("0.0.0.0")).to eq true
            puts "(LIMITER TEST) Scenario: is_blocked? returns true following spam | *PASSED*"
        end
    end

    describe "#get_error_message" do
        it "Increments requestor 3 times, should get error message with a cooldown of 3" do
            $redis.flushdb
            limiter.increment("0.0.0.0")
            limiter.increment("0.0.0.0")
            limiter.increment("0.0.0.0")
            error_message = "Rate limit exceeded. Try again in 3 seconds"
            expect(limiter.get_error_message("0.0.0.0")).to eq error_message
            puts "(LIMITER TEST) Scenario: get_error_message returns correct message following spam | *PASSED*"
        end
    end

    describe "one_request_per_second" do
        it "One request per second should pass" do
            $redis.flushdb
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(1)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(1)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(1)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(1)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(1)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")

            puts "(LIMITER TEST) Scenario: One request per second | *PASSED*"
        end
    end

    describe "two_zero_one_pattern" do
        it "Two requests, then none, then one, then two should pass" do
            $redis.flushdb
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(2)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            sleep(1)
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")
            expect(limiter.is_blocked?("0.0.0.0")).to eq false
            limiter.increment("0.0.0.0")

            puts "(LIMITER TEST) Scenario: Two zero one two pattern | *PASSED*"
        end
    end
end