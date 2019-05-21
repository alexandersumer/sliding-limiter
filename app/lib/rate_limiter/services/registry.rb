# app/lib/rate_limiter/registry.rb

require "singleton"

module RateLimiter
    class Registry
        include Singleton
        
        def initialize
            @registry = {}
        end

        def set(key, value)
            @registry[key.to_s] = value
        end

        def get(key)
            return @registry[key.to_s] if @registry.key?(key.to_s)
            nil
        end
    end
end