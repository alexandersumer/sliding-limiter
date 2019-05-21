# app/lib/rate_limiter/services/cache_interface.rb

# Reference: https://metabates.com/2011/02/07/building-interfaces-and-abstract-classes-in-ruby/

module CacheInterface
	class InterfaceNotImplementedError < NoMethodError
	end

	def self.included(klass)
		klass.send(:include, CacheInterface::Methods)
		klass.send(:extend, CacheInterface::Methods)
		klass.send(:extend, CacheInterface::ClassMethods)
	end

	module Methods
		def api_not_implemented(klass, method_name = nil)
			if method_name.nil?
				caller.first.match(/in \`(.+)\'/)
				method_name = $1
			end
			raise CacheInterface::InterfaceNotImplementedError.new(
				"#{klass.class.name} needs to implement '#{method_name}' for interface #{self.name}!"
			)
		end
	end

	module ClassMethods
		def abstract_method(name, *args)
			self.class_eval do
				define_method(name) do |*args|
					Methods.api_not_implemented(self, name)
				end
			end
		end
	end
end

class Cache
	include CacheInterface

	# increments value associated with child_key by 1 if exists,
	# else create a new entry and set it to 1
	abstract_method :increment, :parent_key, :child_key
	# retreives list of all keys in the hash associated with parent key
	abstract_method :get_keys, :parent_key
	# retreives list of all values in the hash associated with parent key
	abstract_method :get_keys, :parent_key
	# delete entries associated with keys in entries_to_delete
	abstract_method :delete, :parent_key, :entries_to_delete
	# clear the cache
	abstract_method :flush
end