# config/initializers/memcached.rb

require 'dalli'

options = { :namespace => "app", :compress => true }

$memcached = Dalli::Client.new('localhost:11211', options)