# app/lib/rate_limiter/services/limiter.rb

module RateLimiter
	class Limiter
		def initialize(key, threshold, interval, accuracy, cache_client)
			@key = key
			@threshold = threshold
			@interval = interval
			@bucket_cache = cache_client
			@accuracy = accuracy
		end
	
		public
	
		def is_blocked?(requestor_id)
			delete_expired_buckets(requestor_id)
			total_requests = get_total_count(requestor_id)
			is_blocked = total_requests >= @threshold
			return is_blocked
		end
	
		def get_error_message(requestor_id)
			cooldown = get_cooldown(requestor_id)
			error_message = "Rate limit exceeded. Try again in #{cooldown} seconds"
			return error_message
		end
	
		def increment(requestor_id)
			bucket = get_bucket
			cache_key = get_cache_key(requestor_id)
			@bucket_cache.increment(cache_key, bucket)
		end
	
		private
	
		def get_total_count(requestor_id)
			cache_key = get_cache_key(requestor_id)
			counts = @bucket_cache.get_values(cache_key)
			total_requests = counts.reduce(0, :+)
			return total_requests
		end
	
		def get_cooldown(requestor_id)
			current_time = get_current_time
			all_buckets = get_all_buckets(requestor_id)
			cooldown = all_buckets.min - current_time + @interval
			return cooldown
		end
	
		def delete_expired_buckets(requestor_id)
			current_time = get_current_time
			cache_key = get_cache_key(requestor_id)
			all_buckets = get_all_buckets(requestor_id)
			oldest_bucket = get_bucket(current_time - @interval)
			to_delete = all_buckets.select { |bucket| bucket <= oldest_bucket }
			@bucket_cache.delete(cache_key, to_delete) if to_delete.length != 0
		end
	
		def get_all_buckets(requestor_id)
			cache_key = get_cache_key(requestor_id)
			all_buckets = @bucket_cache.get_keys(cache_key)
			return all_buckets
		end
	
		def get_current_time
			current_time = Time.now.to_i
			return current_time
		end
	
		def get_bucket(time = get_current_time)
			bucket = (time * @accuracy).floor
			return bucket
		end
	
		def get_cache_key(requestor_id)
			cache_key = "#{@key}_#{requestor_id}"
			return cache_key
		end
	end
end
