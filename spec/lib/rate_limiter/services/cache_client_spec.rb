# spec/lib/rate_limiter/services/cache_client_spec.rb

RSpec.describe RateLimiter::CacheClient do
    subject { described_class }
    let(:cache_client) { described_class.new }

    describe "#increment" do
        it "Increments or sets value associated with key" do
            cache_client.flush
            cache_client.increment("requestor1_key", "123")
            expect(cache_client.get_keys("requestor1_key")).to eq [123]
            expect(cache_client.get_values("requestor1_key")).to eq [1]
            cache_client.increment("requestor1_key", "123")
            expect(cache_client.get_keys("requestor1_key")).to eq [123]
            expect(cache_client.get_values("requestor1_key")).to eq [2]
            cache_client.increment("requestor2_key", "124")
            expect(cache_client.get_keys("requestor2_key")).to eq [124]
            expect(cache_client.get_values("requestor2_key")).to eq [1]
            cache_client.increment("requestor2_key", "124")
            expect(cache_client.get_keys("requestor2_key")).to eq [124]
            expect(cache_client.get_values("requestor2_key")).to eq [2]
        end
    end

    describe "#delete" do
        it "Deletes entries with given keys" do
            cache_client.flush
            cache_client.increment("requestor1_key", "123")
            cache_client.increment("requestor1_key", "123")
            cache_client.increment("requestor2_key", "124")
            cache_client.increment("requestor2_key", "124")
            cache_client.delete("requestor2_key", [123, 124])
            expect(cache_client.get_keys("requestor2_key")).to eq []
            expect(cache_client.get_values("requestor2_key")).to eq []
        end
    end
end
