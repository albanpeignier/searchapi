module SearchApi
  module Search
    module Callbacks
      CALLBACKS = %w(before_find_options)

      def self.append_features(base)  #:nodoc:
        super

        base.class_eval do
          %w(find_options).each do |method|
            alias_method_chain method, :callbacks
          end
        end

        CALLBACKS.each do |method|
          base.class_eval <<-"end_eval"
            def self.#{method}(*callbacks, &block)
              callbacks << block if block_given?
              write_inheritable_array(#{method.to_sym.inspect}, callbacks)
            end
          end_eval
        end
      end
    
      def find_options_with_callbacks
        callback(:before_find_options)
        find_options_without_callbacks
      end
    
      def before_find_options
      end


      private
    
      def callback(method)
        callbacks_for(method).each do |callback|
          result = case callback
            when Symbol
              self.send(callback)
            when String
              eval(callback, binding)
            when Proc, Method
              callback.call(self)
            else
              if callback.respond_to?(method)
                callback.send(method, self)
              else
                raise SearchApiError, "Callbacks must be a symbol denoting the method to call, a string to be evaluated, a block to be invoked, or an object responding to the callback method."
              end
          end
          return false if result == false
        end

        result = send(method) if respond_to?(method)

        return result
      end

      def callbacks_for(method)
        self.class.read_inheritable_attribute(method.to_sym) or []
      end
    end
  end
end