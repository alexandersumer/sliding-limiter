# Sliding window rate limiter module for Ruby on Rails

Hello, this is my first ever rails application so I hope I didn't reak too many rules :)

## Application Usage

The following usage instructions are for Mac.

This application requires: Ruby, Rails, Bundler and Redis.

To install redis, run the command:

`$ brew install redis`

A live redis instance is required for this application as well as for running rspec tests (unless you are using the local memory cache). To start redis on localhost and port 6379, run the command:

`$ redis-server`

Navigate to the application root directory. If running the application for the first time, the required dependancies can be installed using the command:

`$ bundle install`

To start the application, run the command:

`$ rails s`

Navigate to `http://localhost:3000/` and the message "You are welcome!" should be printed. If 100 requests are made to `http://localhost:3000/` within 1 hour, a 429 HTTP Status is returned along with the error message: "Rate limit exceeded. Try again in #{cooldown} seconds"

If you are running this on a machine that is not a Mac, then a docker-compose.yml file is included for you to run this application through docker. Just navigate to the application root directory and run the command:

`$ docker-compose up`


## Module Usage

The RateLimiter module exposes 3 methods and a constructor through the class LimiterClient:

The constructor takes in the following arguments:

 * key: a unique identifier used as part of the cache key to retreive bucket hashes for requestors sharing the same Limiter instance and cache
 * threshold: the maximum number of requests a requestor can make within 1 interval
 * interval: length of 1 interval in secodns
 * accuracy: the accurate of the rate limiter increases the more buckets we have for each interval. A value of 1 means each interval is divided into interval buckets, 1 second each. A value of 4 means the interval is divided into 4 * interval buckets, 1/4 seconds each.
 * cache: a key-value store where the value is a hashmap. Must excend Cache from CacheInterface and implement the abstract methods.

```ruby
initialize(key, threshold, interval, accuracy, cache = RedisCache.new)
```

To call this method, pass in the ID of the requestor (IPv6 is a good choice since it is unique).
This method has a side effect since it makes a call to delete_expired_buckets, which deletes all buckets outside the current interval. The decision to have this side effect was made to expose less of the internal implementation to the user.
```ruby
is_blocked?(requestor_id)
```

This method also takes in an ID. This method returns an error message to accompany the 429 HTTP status and includes a countdown till the requestor becomes unblocked again.
```ruby
get_error_message(requestor_id)
```

This method also takes in an ID. It makes a call to the cache to increment the number of requests in the current time bucket. If such requestor doesn't exist in the cache or such bucket doesn't exist, it initialises the requestor and sets the value for the current time bucket to 1.

```ruby
increment(requestor_id)
```

Here is an example use case:

```ruby
limiter = RateLimiter::LimiterClient.new(
    "unique_id", threshold, interval, accuracy, redis_cache
)

if limiter.is_blocked?(request.ip)
    render status: TOO_MANY_REQUESTS, plain: limiter.get_error_message(request.ip)
else
    limiter.increment(request.ip)
end
```

## Testing

Testing is done using rspec, run the following command to run all tests:

`rspec`

Testing is done at the 1 second scale, guaranteeing accuracy at 1 second intervals. More extensive testing guaranteeing accuracy at the microsecond interval seemed unnecessary.

If the accuracy value is changed, for example, from 4 to 1, some of the tests will fail because this introduces in accuracies. For example, if each bucket represents 1 second and the rate limit is 1 request per second, then if a requestor does 1 request in the second half of second 1 and the next request in the first half of second 2, then our 1 second window is not violated (we did 1 request in second 1 and 1 request in second 2) but if we look at the interval from half second 1 to half second 2 then we have done two requests within 1 second, which violates the 1 request per second condition. To deal with this inaccuracy, the accuracy value passed into the LimiterClient constructor can be increased.

If the accuracy value is changes to 1, then the unit tests will sometimes pass and sometimes fail depending on the exact time each request is fired within each 1 second bucket. According to my statistical tests (about 30 repetitions), with an accuracy value of 1, unit tests will pass about 40% of the time (with existing test setup). With an accuracy value of 2, unit tests will pass about 80% of the time. With an accuracy value of 4, unit tests will pass 100% of the time.

## System design

If you look back through my commit history, you will see that I initially started with a fixed window implementation. However, may edge case tests didn't pass this that implementation, showing that it was simply inaccurate. The edge cases that were failing are touched upon in the Testing section of this document. In short, if you treat each interval as fixed, and then block the user for the remainder of that interval, then the user can send more requests than the rate limiter should allow (up to 2x the threshold) and if the requestor is blocked for a full interval, then this is also incorrect because if they spam at half way through the window and get blocked for a full window then this means they can do a maximum of threashold requests in 1.5 intervals.

I decided to change my implementation from a fixed window to a sliding window. Changing the implementation was an important part of the system design because it put me into the shoes of someone trying to extend or maintain this implementation. As a result I made a few changes to the design to make it more plug and play friendly.

The sliding window apporach can be implemented in two ways. One way is to store the timestamps of all requests and then remove any timestamps that go outside the current interval. This approach is accurate but in terms of time and space complexity, we are bounded by the number of requests, which depends on user input. The other approach is to give the user control over accuracy, which is traded for performance. Higher accuracy has a higher space and time compexity.

The sliding window approach implemented here divides an interval up into discrete buckets, each representing a slice of time. The time each slice represents depends on the value of the accuracy variable which is inputed by the user.

Suppose each bucket represents 1 second. When a requst comes in we get the current UNIX time and round it to the nearest integer value (time in seconds since EPOCH). This will be the key for the bucket in this requestors hashmap of buckets. If the bucket contains a value, then we increment it, if the bucket contains no value, then we set the value to 1.

Each time we check if a requestor is blocked, we need to get the total count of requests between current time and an interval ago. To do this accurately, we first need to delete all buckets that fall outside this interval. Deletion is O(number of bucets per interval). This can be a big number if the value of accuracy is high. However, in practical scenarios, suppose we want to rate limit to 100 requests per hour, then an accuracy value of 1/60 would be reasonable, allowing for 1 minute buckets, which is 60 buckets per interval per user.

The system is designed such that it is cache agnostic. Any key-value store can be used as long as it provides the following basic functionality:

```ruby
# increments value associated with timestamp by 1 if exists,
# else create a new entry and set it to 1
increment(requestor_key, timestamp)
# retreives list of all keys in the hash associated with parent key
get_keys(requestor_key)
# retreives list of all values in the hash associated with parent key
get_keys(requestor_key)
# delete entries associated with keys in entries_to_delete
delete(requestor_key, entries_to_delete)
```

In terms of running this rate limiting module on a distributed systems, redis will do a decent job but there are drawbacks to using redis. For example, network delay means there can be inaccuracies, we have no control over the internal implementation of redis, for example, redis doesn't have built in compression, so for UNIX time string, a lot of space will be wasted which can be avoided since the timestamps have overlapping prefixes which can be compressed.

In this implementation I provide the option to use a local memory cache. This is actually not a terrible option as long as we have a services that regularly synchronises the counts in an eventually consistent matter. This is because load balancers have a sticky session these days, so a locasl memory cache will work fairly without having to deal with network delay associated with redis sycnronisation.

## Limitations and Enhancements

One limitation is to do with the way I have set up the unit tests. The tests require on a live instance of redis running. Most of the tests are time based, and simmulate time by running `sleep(x)`. In order to reset the rate limiter counts from one test to the next, `$redis.flushdb` is used, which isn't ideal because this couples the tests with redis, but ideally I want the tests to be cache agnostic.

There are two ways to do this:

 * run `sleep(interval)` at the start of time based tests to reset the rate limiter counts but this is not great because it will cause tests to run even longer
 
 * Using a fake cache. I ran into a lot of trouble trying to set up a fake cache because I couldn't find one that worked properly. guilleiguaran/fakeredis isn't well maintained and the build is failing. I considered using a local hash to simulate redis but that's lame. So I decided to just go with a live redis instance for testing.

In terms of performance, I think a circular buffer is worth considering. Modelling an interval as a circular buffer means we don't have to perform expensive deletions and instead overright values once we loop around. The problem with this approach is that the bucket names cannot be the actual UNIX time but instead we have to use (UNIX time % interval). This makes a few things more complicated, for example, it makes it more difficult to work out the cooldown period since right now we rely on the name of the bucket being the UNIX time to perform that calculation.

Other improvements include travis and docket support.