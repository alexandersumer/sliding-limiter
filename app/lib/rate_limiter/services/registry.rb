# app/lib/rate_limiter/registry.rb

require "singleton"

module RateLimiter
    class Registry
        include Singleton
        
        def initialize
            @registry = {}
        end

        def set(key, value = nil)
            @registry[key.to_s] = value
            self
        end

        def get(key, default = nil)
            return @registry[key.to_s] if @registry.key?(key.to_s)
            default
        end
    end
end