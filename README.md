# Sliding window rate limiter module for Ruby on Rails

Hello, this is my first ever rails application! I really enjoyed learning this framework, it's very pleasant to work with.

## Application Usage

The following usage instructions are for Mac (will be similar to Linux).

This application requires: Ruby (I tested on 2.5.5 and 2.6.3), Rails, Bundler and Redis.

To install redis, run the command:

`$ brew install redis`

A live redis instance is required for this application as well as for running rspec tests (unless you are using the local memory cache). To start redis on localhost and port 6379, run the command:

`$ redis-server`

Now clone the repo:

`$ git clone git@github.com:alexanderj2357/sliding-limiter.git`

Navigate to the application root directory. If running the application for the first time, the required dependancies can be installed using the command:

`$ bundle install`

To start the application, run the command:

`$ rails s`

Navigate to `http://localhost:3000/` and the message "You are welcome!" should be printed. If 100 requests are made to `http://localhost:3000/` within 1 hour, a 429 HTTP Status is returned along with the error message: "Rate limit exceeded. Try again in #{cooldown} seconds"

Docker support will be pushed once I get it working so that you can run this anywhere ;)

## Module Usage

The RateLimiter module exposes 3 methods and a constructor through the class LimiterClient:

The constructor takes in the following arguments:

 * key: a unique identifier used as part of the cache key to retreive bucket hashes for requestors sharing the same Limiter instance and cache
 * threshold: the maximum number of requests a requestor can make within 1 interval
 * interval: length of 1 a full window of time (Time.now - interval ago) in secodns
 * accuracy: a float representing accuracy of rate limiter (can it guarantee x req per y time?) the accuracy of the rate limiter increases the more buckets we have for each interval. A value of 1 means each interval is divided into buckets(time slots) 1 second each. A value of 4 means the interval is divided into 4 * 1 second buckets, so representing 1/4 seconds each.
 * cache: a key-value store where the value is another key-value store. Must implement the abstract methods in `CacheInterface::Cache`.

```ruby
initialize(key, threshold, interval, accuracy, cache = RedisCache.new)
```

To call this method, pass in the ID of the requestor (IPv6 is a good choice since it is unique). This method has a side effect since it makes a call to delete_expired_buckets, which deletes all buckets outside the current interval. The decision to have this side effect was made to expose less of the internal implementation to the user.
```ruby
is_blocked?(requestor_id)
```

This method also takes in an ID. This method returns an error message to accompany the 429 HTTP status and includes a countdown till the requestor becomes unblocked again.
```ruby
get_error_message(requestor_id)
```

This method also takes in an ID. It makes a call to the cache to increment the number of requests in the Time.now bucket. If this requestor doesn't exist in the cache or if the Time.now bucket doesn't exist, it initialises the requestor and sets the value for the Time.now bucket to 1.

```ruby
increment(requestor_id)
```

Here is an example use case:

```ruby
# rate limit requestors to 100 req per any 1 hour interval
# correctness is guaranteed at scales greater than 1 second
limiter = RateLimiter::LimiterClient.new("handle_authentication_requests", 100, 3600, 1)

if limiter.is_blocked?(request.ip)
    render status: TOO_MANY_REQUESTS, plain: limiter.get_error_message(request.ip)
else
    limiter.increment(request.ip)
end
```

## Testing

Testing is done using rspec, run the following command to run all tests:

`$ rspec`

Testing is done at the 1 second scale, they guarantee accuracy at 1 second time buckets. More extensive testing guaranteeing accuracy at the microsecond interval seemed unnecessary.

If the accuracy value is changed, for example, from 4 to 1, some of the tests will fail because this introduces in accuracies. For example, if each bucket represents 1 second and the rate limit is 1 request per second, then if a requestor does 1 request in the second half of second 1 and the next request in the first half of second 2, then our 1 second window is violated. Why? Between half second one and half second 2 is 1 second interval and we did 2 requests in one second violating the 1req/s rule. To deal with this inaccuracy, the accuracy value passed into the LimiterClient constructor can be increased.

If the accuracy value is changes to 1, then the unit tests will sometimes pass and sometimes fail depending on the exact time each request is fired within each 1 second bucket. According to my statistical tests (about 30 repetitions), with an accuracy value of 1, unit tests will pass about 40% of the time (with existing test setup). With an accuracy value of 2, unit tests will pass about 80% of the time. With an accuracy value of 4, unit tests will pass 100% of the time.

## System design

If you look back through my commit history, you will see that I initially started with a fixed window implementation. However, edge case tests didn't pass this that implementation, showing that it was simply inaccurate. The edge cases that were failing are touched upon in the Testing section of this document. In short, if you treat each interval as fixed, and then block the user for the remainder of that interval, then the user can send more requests than the rate limiter should allow (up to 2x the threshold) and if the requestor is blocked for a full interval, then this is also incorrect because if they spam at half way through the window and get blocked for a full window then this means they can do a maximum of threashold requests in 1.5 intervals. 

I decided to change my implementation from a fixed window to a sliding window to deal with these iaccuracies. Changing the implementation was an important part of the system design process because it put me into the shoes of someone trying to extend this implementation. As a result I made a few changes to the design to make it more plug-and-play friendly.

The sliding window apporach can be implemented in two ways. One way is to store the timestamps of all requests and then remove any timestamps that go outside the current interval. This approach is accurate but time and space complexitiesn grow with number of requests, which depends on user input. The other approach is to treat an interval as a series of discrete buckets, labelled by timestamps, starting at `Time.now - interval` and ending at Time.now and the width (accuracy) is determinsed by the user. Accuracy is traded for performance. Higher accuracy has higher space and time compexities.

Suppose each bucket represents 1 second. When a requst comes in we get the current UNIX time and round it to the nearest integer value. This will be the key for the bucket in this requestors bucket->count hashmap. if the bucket contains a value, then we incrment it, elsif the bucket contains no value, then we set the value to 1.

Each time we check if a requestor is blocked, we need to get the total count of requests between Time.now and an interval ago (current window). To do this accurately, we first need to delete all buckets that fall outside the current window. Deletion is O(number of entries in hashmap). This can be a big number if the value of accuracy is high. However, in a practical scenario, e.g. suppose we want to rate limit to 100 requests per hour, then an accuracy value of 1/60 would be reasonable, allowing for 1 minute buckets, which is 60 buckets per window per user.

The system is designed such that the implementation of the cache is abstracted away. Any key-value store can be used as long as it provides the following basic functionality:

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

The reason I decided to use an 'interface' for the cache rather than just relying on duck typing is because I wanted to reduce clutter in my Limiter class and abstract away the cache completely and have a different class handle method implementation and throw exceptions.

In terms of running this rate limiter module in production on a distributed system, a redis cluster can be used but it has some drawbacks:

 * Redis clusters use a master-slave architecutre, with multiple slave replicas for a master. This is prone to SPOF.
 * Redis doesn't have built-in compression. They keys to our buckets are UNIX time, this they have overlapping prefixes, which can be compressed to reduce memory usage.
 * Network delay associated with reading and writing from a remote server can result in inaccuracies

Another approach would be to use a local memory cache on each node with a services that regularly synchronises the counts in an eventually consistent manner to some datastore like mongodb. This is because load balancers have a sticky session feature these days, so a locasl memory cache means it is highly likely we get correct counts for users being directed to the same node by the LB.

## Limitations and enhancements

One limitation is to do with the way I have set up the unit tests. The tests require on a live instance of redis running. Most of the tests are time based, and simmulate time by running `sleep(x)`. In order to reset the rate limiter counts from one test to the next, `$redis.flushdb` is used, which isn't ideal because this couples the tests with redis, but ideally I want the tests to be cache agnostic.

There are two ways to do this:

 * run `sleep(interval)` at the start of time based tests to reset the rate limiter counts but this is not great because it will cause tests to run even longer
 
 * Using a fake cache. I ran into a lot of trouble trying to set up a fake cache because I couldn't find one that worked properly. `guilleiguaran/fakeredis` isn't well maintained anymore and the build is failing. I considered using a local memory hash to simulate redis but I decided to just go with a live redis instance for testing because it is a better representation of how the module will be used in production.

In terms of performance, I think a circular buffer is worth considering. Modelling an interval as a circular buffer means we don't have to perform expensive deletions and instead overright values once we loop around. The problem with this approach is that the bucket names cannot be the actual UNIX time but instead we have to use (UNIX time % interval). This makes a few things more complicated, for example, it makes it more difficult to work out the cooldown period since right now we rely on the name of the bucket being the UNIX time to perform that calculation.

In terms of flexibility, one enhanacement I can think of is passing the threshold and interval into the `is_blocked` and `increment` methods rather than the constructor so that we can have different rates for different users. We can store the rates for each user in our cache, which means we have to modify the cache interface a little to expose set and get methods.

The rate limiter can also benefit from exposing `whitelist` and `blacklist` methods to allow certain users unrestricted access (whitelist) and completely ban some users (blacklist).
