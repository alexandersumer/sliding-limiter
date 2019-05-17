# spec/lib/services/redis_client_spec.rb

require_relative '../../../app/lib/rate_limiter/services/cache'

RSpec.describe RateLimiter::Cache do
    subject { described_class }
    let(:cache) { described_class.new }

    describe '#get_count' do
        it 'gets value associated with key' do
            cache.flushdb
            cache.init_requestor('key', 10)
            expect(cache.get_count('key')).to eq '1'
        end

        it 'returns nil if key does not exist' do
            cache.flushdb
            expect(cache.get_count('key')).to eq nil
        end
    end

    describe '#increment_count' do
        it 'increments the value associated with a key by 1' do
            cache.flushdb
            cache.init_requestor('key', 10)
            cache.increment_count('key')
            expect(cache.get_count('key')).to eq '2'
        end

        it 'initializes key with value 1 if does not exist' do
            cache.flushdb
            cache.increment_count('key')
            expect(cache.get_count('key')).to eq '1'
        end
    end

    describe '#get_cooldown' do
        it 'returns the timen to live for a key' do
            cache.flushdb
            cache.init_requestor('key', 10)
            expect(cache.get_cooldown('key')).to eq 10
        end

        it 'returns nil if key is expired' do
            cache.flushdb
            cache.init_requestor('key', 2)
            sleep(2.seconds)
            expect(cache.get_cooldown('key')).to eq nil
        end

        it 'returns -2 if key does not exist' do
            cache.flushdb
            expect(cache.get_cooldown('key')).to eq nil
        end
    end
end