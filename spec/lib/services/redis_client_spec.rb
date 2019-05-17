# spec/lib/services/redis_client_spec.rb

require_relative '../../../app/lib/rate_limiter/services/redis_client'

RSpec.describe RateLimiter::RedisClient do
    subject { described_class }
    let(:redis_client) { described_class.new }

    describe '#get' do
        it 'gets value associated with key' do
            redis_client.flushdb
            redis_client.set('key', 1, 10)
            expect(redis_client.get('key')).to eq '1'
        end

        it 'returns nil if key does not exist' do
            redis_client.flushdb
            expect(redis_client.get('key')).to eq nil
        end
    end

    describe '#incr' do
        it 'increments the value associated with a key by 1' do
            redis_client.flushdb
            redis_client.set('key', 1, 10)
            redis_client.incr('key')
            expect(redis_client.get('key')).to eq '2'
        end

        it 'creates new key and sets its value to 1 if does not exist' do
            redis_client.flushdb
            redis_client.incr('key')
            expect(redis_client.get('key')).to eq '1'
        end
    end

    describe '#ttl' do
        it 'returns the time to live for a key' do
            redis_client.flushdb
            redis_client.set('key', 1, 10)
            expect(redis_client.ttl('key')).to eq 10
        end

        it 'returns nil if key is expired' do
            redis_client.flushdb
            redis_client.set('key', 1, 2)
            sleep(2.seconds)
            expect(redis_client.ttl('key')).to eq nil
        end

        it 'returns nil if key does not exist' do
            redis_client.flushdb
            expect(redis_client.ttl('key')).to eq nil
        end
    end
end