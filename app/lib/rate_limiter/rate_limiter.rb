# app/lib/rate_limiter/rate_limiter.rb

require 'client'
require 'limiter'
require 'cache'

module RateLimiter
	autoload :Client,  'client'
	autoload :Limiter, 'limiter'
	autoload :Cache,   'cache'
end