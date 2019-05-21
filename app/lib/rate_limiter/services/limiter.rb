# app/lib/rate_limiter/services/limiter.rb

module RateLimiter
	class Limiter
		# This rate limiter implements a sliding window algorithm.
		# A time window is divided into discrete buckets, each representing
		# a slice of a time window, the size of each slice depends on accuracy value.
		# Each requestor is assigned a hash map of buckets, each bucket contains the
		# number of requests that were made in that slice of time.
		# Once a bucket falls outside the current time window, it is deleted.
		
		def initialize(key, threshold, interval, accuracy, cache = RedisCache.new)
			@key = key				# [String]	Identifier for current instance
			@threshold = threshold 	# [Integer]	Max number of requests per time window
			@interval = interval	# [Integer]	Number of seconds per time window
			@accuracy = accuracy	# [Float]	Number of buckets per second
			@buckets_cache = cache	# [Object]	Instance of a cache to store hashes of buckets
		end
	
		public
	
		def is_blocked?(requestor_id)
			# Delete all expired buckets to get an accurate total count
			delete_expired_buckets(requestor_id)
			# Get total number of requests this requestor made in current time window
			total_requests = get_total_count(requestor_id)
			# Check if total number of requests made in current time window exceeds threshold
			return total_requests >= @threshold
		end
	
		def get_error_message(requestor_id)
			cooldown = get_cooldown(requestor_id)
			return "Rate limit exceeded. Try again in #{cooldown} seconds"
		end
	
		def increment(requestor_id)
			bucket = get_bucket_key
			cache_key = get_cache_key(requestor_id)
			# increment number of requests by 1 if requestor exixts,
			# else, create a new entry for requestor and set count to 1
			@buckets_cache.increment(cache_key, bucket)
		end
	
		private
	
		def get_total_count(requestor_id)
			cache_key = get_cache_key(requestor_id)
			# get the counts stored in all buckets
			# this is always called after a call to delete_expired_buckets
			# therefore, we will get the counts for current time window
			counts = get_all_bucket_values(requestor_id)
			# add all the counts to get total count for current time window
			return counts.reduce(0, :+)
		end
	
		def get_cooldown(requestor_id)
			current_time = get_current_time
			all_bucket_keys = get_all_bucket_keys(requestor_id)
			# get the time in seconds associated with the oldest bucket
			oldest_bucket = (all_bucket_keys.min / @accuracy).floor
			# (current_time - oldest_bucket) gives how long we have waited
			# @interval - how long we have waited gives the cooldown
			return @interval - (current_time - oldest_bucket)
		end
	
		def delete_expired_buckets(requestor_id)
			current_time = get_current_time
			cache_key = get_cache_key(requestor_id)
			all_bucket_keys = get_all_bucket_keys(requestor_id)
			# get the oldest bucket in the current time window
			oldest_bucket = get_bucket_key(current_time - @interval)
			# get all buckets outside the current time window
			entries_to_delete = all_bucket_keys.select { |bucket| bucket <= oldest_bucket }
			# delete all buckets outside the current time window
			# if no buckets to delete exist, then avoid making a call to the cache
			if entries_to_delete.length != 0
				@buckets_cache.delete(cache_key, entries_to_delete)
			end
		end
	
		def get_all_bucket_keys(requestor_id)
			cache_key = get_cache_key(requestor_id)
			return @buckets_cache.get_keys(cache_key)
		end

		def get_all_bucket_values(requestor_id)
			cache_key = get_cache_key(requestor_id)
			return @buckets_cache.get_values(cache_key)
		end
	
		def get_current_time
			return Time.now.to_i
		end
	
		def get_bucket_key(time = get_current_time)
			# the key for each bucket is time since EPOCH * accuracy
			# higher accuracy value means each bucket represents smaller time units
			return (time * @accuracy).floor
		end
	
		def get_cache_key(requestor_id)
			# The requestor ID is part of the cache key so that each requestor
			# has their own buckets hash and multiple requestors can share a cache
			return "#{@key}_#{requestor_id}"
		end
	end
end
