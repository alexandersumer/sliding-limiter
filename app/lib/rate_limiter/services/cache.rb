# app/lib/rate_limiter/services/cache.rb

module RateLimiter
    class Cache
        attr_reader :cache

        def initialize(cache_client = RedisClient.new)
            @cache = cache_client
        end

        def get_count(key)
            cache.get(key)
        end

        def block_requestor(key, period)
            cache.set(key, 1, period)
        end

        def init_requestor(key, period)
            cache.set(key, 1, period)
        end

        def increment_count(key)
            cache.incr(key)
        end

        def get_cooldown(key)
            cache.ttl(key)
        end

        def flush
            cache.flush
        end
    end
end