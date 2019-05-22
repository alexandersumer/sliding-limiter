# app/lib/rate_limiter/limiter_client.rb

require_relative './services/limiter'
require_relative './services/redis_cache'
require_relative './services/local_mem_cache'
require_relative './services/cache_client'

module RateLimiter
	class LimiterClient
		# Create a LimiterClient object.
		#
		# @param [String]	key			A unique identifier for Limiter
		# @param [Integer]	threshold	Maximum number of allowed requests per time window, > 0
		# @param [Integer]	interval	Number of seconds per time window, > 0
		# @param [Integer]	accuracy	Higher value trades performance for more accuracy
		#								A value of 1 means 1 second granularity
		#								A value of 4 means 1/4 second granularity
		# @param [Object]	cache		An instance of a cache object mapping keys to
		#								hash maps, extends Cache class from CacheInterface
		#                               and implements the required abstract methods
		def initialize(key, threshold, interval, accuracy, cache = CacheClient.new(RedisCache.new))
			if !(threshold.is_a?(Integer)) && threshold < 0
				raise "threshold must be a positive integer."
			end

			if !(interval.is_a?(Integer)) && interval < 0
				raise "interval must be a positive integer."
			end

			if !(accuracy.is_a?(Numeric))
				raise "accuracy must be a number."
			end

			if !(cache.is_a?(CacheClient))
				raise "cache must implement CacheClient."
			end

			@limiter = RateLimiter::Limiter.new(key, threshold, interval, accuracy, cache)
		end

		# Check if a particular requestor is allowed or blocked
		# Side effect: Deletes expired buckets
		def is_blocked?(requestor_id)
			return @limiter.is_blocked?(requestor_id)
		end

		# Get an error message and cooldown in seconds for a particular blocked requestor
		def get_error_message(requestor_id)
			return @limiter.get_error_message(requestor_id)
		end

		# Increment the request count for a particular requestor by 1 if requestor exists,
		# if this is the first request by this requestor then create a new entry and set it to 1
		def increment(requestor_id)
			@limiter.increment(requestor_id)
		end
	end
end
