# spec/lib/services/redis_client_spec.rb

require_relative '../../../app/lib/rate_limiter/services/redis_client'

RSpec.describe RateLimiter::RedisClient do
    subject { described_class }
    let(:redis_client) { described_class.new }

    describe '#get' do
        it 'get the value associated with a key' do
            redis_client.flushdb
            redis_client.set('a', 1, 10)
            expect(redis_client.get('a')).to eq '1'
        end
    end

    describe '#incr' do
        it 'get the time to live for a key' do
            redis_client.flushdb
            redis_client.set('a', 1, 10)
            redis_client.incr('a')
            expect(redis_client.get('a')).to eq '2'
        end
    end

    describe '#ttl' do
        it 'get the time to live for a key' do
            redis_client.flushdb
            redis_client.set('a', 1, 10)
            expect(redis_client.ttl('a')).to eq 10
        end
    end
end