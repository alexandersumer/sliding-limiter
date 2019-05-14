module RateLimiter
    class Cache
        attr_reader :cache
        def initialize(cache = $redis)
            @cache = cache
        end

        def get(key)
            cache.get(key)
        end

        def set(key, value, opts = {})
            cache.set(key, value)
            cache.expire(key, opts[:duration])
        end

        def incr(key)
            cache.incr(key)
        end

        def ttl(key)
            cache.ttl(key)
        end
    end
end