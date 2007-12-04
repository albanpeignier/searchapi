module SearchApi

  # The module holds all SearchApi search features
  
  module Search
    
    # The SearchApi::Search::Base class is able to encapsulate search parameters for a given model.
    #
    # In order to search for instances of your model Stuff, you must:
    #
    # - ensure Stuff responds to <tt>search_api_bridge</tt> method.
    #   This is, by default, the case of ActiveRecord::Base subclasses.
    #
    # - define a subclass of SearchApi::Search::Base that uses Stuff as a model:
    #
    #     class StuffSearch < SearchApi::Search::Base
    #       # search for Stuff
    #       model Stuff
    #     end
    #
    # Assuming Stuff is an ActiveRecord::Base subclass, automatic search attributes
    # are defined in StuffSearch. You can immediately use them:
    #
    # Those two statements are strictly equivalent:
    #
    #   Stuff.find(:all, {:birth_date => Time.now})
    #   Stuff.find(:all, StuffSearch.new(:birth_date => Time.now).find_options)
    #
    # So far, so good. But that's not very funky.
    #
    # You can also define your own search attributes:
    #
    #   class StuffSearch < SearchApi::Search::Base
    #     # search for Stuff
    #     model Stuff
    #     search_accessor :max_age do |search|
    #       { :conditions => ['birth_date > ?', Time.now - search.max_age.years]}
    #     end
    #   end
    # 
    # This allows you to perform searches on age:
    #
    #   Stuff.find(:all, StuffSearch.new(:max_age => 20).find_options)
    #
    # You can mix search keys:
    #
    #   Stuff.find(:all, StuffSearch.new(:max_age => 20, :sex => 'M').find_options)
    class Base
    
      VALID_SEARCH_ATTRIBUTE_OPTIONS = [ :store_as, :default ]

      class << self

        # Without any argument, returns the model of this SearchApi::Search::Base class.
        #
        # With a single argument, this method defines the model of this SearchApi::Search::Base class.
        #
        # The model must respond_to the <tt>search_api_bridge</tt> method,
        # which should return an object that acts like SearchApi::Bridge::Base.
        # 
        # The model can't be defined twice.
        #
        # Some automatic search accessors may be defined when the model is set.
        # See:
        # - Bridge::Base#automatic_search_attribute_builders
        # - Bridge::ActiveRecord#automatic_search_attribute_builders
        #
        # Example:
        #   class StuffSearch < SearchApi::Search::Base
        #     # search for Stuff
        #     model Stuff
        #     ...
        #   end
        #
        #   StuffSearch.model # => Stuff
        def model(*args)
          # returns model when no arguments
          return @model if args.empty?
        
          # can't set model twice
          raise "model is already set" if @model
        
          # fetch optional options
          options = if args.last.is_a?(Hash) then args.pop else {} end
        
          # make sure model is the only last argument
          raise ArgumentError.new("Bad arguments for model") unless args.length == 1
        
        
          model = args.first
        
          # assert model responds_to search_api_bridge
          raise ArgumentError.new("#{model} doesn't respond to search_api_bridge") unless model.respond_to?(:search_api_bridge)
        
          # set model
          @model = model
        
          # infer automatics search accessors from model
          add_automatic_search_attributes(options)
        
          nil # don't pollute class creation
        end
      
      
        # This is how you add search attributes to your SearchApi::Search::Base class.
        #
        # Adding a search attribute has the following consequences:
        # - A writer, a reader, an interrogation reader, and a ignored reader are defined.
        #
        #   Writer and reader act as usual. Interrogation reader acts as ActiveRecord::Base's one.
        #
        #   Ignorer reader tells whether the search attribute is ignored or not.
        # 
        #     # Defines following StuffSearch instance methods:
        #     # - :a, :a=, :a? and :a_ignored?
        #     # - :b, :b=, :b? and :b_ignored?
        #     class StuffSearch < SearchApi::Search::Base
        #       model Stuff
        #       search_accessor :a, :b
        #     end
        #
        # - The method <tt>find_options_for_[search attribute]</tt> is defined,
        #   if block is provided.
        #
        # The optional block takes a single parameter: a SearchApi::Search::Base instance.
        #
        # Its result should be enough to define a model search.
        #
        # In case of ActiveRecord models, it should be a valid Hash that can be used as
        # ActiveRecord::Base.find argument.
        #
        # Example:
        #   class StuffSearch < SearchApi::Search::Base
        #     model Stuff
        #     search_accessor :max_age do |search|
        #       { :conditions => ['birth_date > ?', Time.now - search.max_age.years]}
        #     end
        #   end
        #
        # You can avoid passing a block, and define the <tt>find_options_for_[search attribute]</tt>
        # method later:
        #
        #   class StuffSearch < SearchApi::Search::Base
        #     model Stuff
        #     search_accessor :max_age
        #     def find_options_for_max_age
        #       { :conditions => ['birth_date > ?', Time.now - max_age.years]}
        #     end
        #   end
      
        def search_accessor(*args, &block)
        
          # extract SearchAttributeBuilder instances from arguments
        
          search_attributes_builders = if block.nil? && args.length == 1 && args.first.is_a?(SearchAttributeBuilder)
            # argument is a single SearchAttributeBuilder instance
          
            args
          
          else
            # arguments are search attribute names and options
          
            options = if args.last.is_a?(Hash) then args.pop else {} end
            args.map do |search_attribute|
              SearchAttributeBuilder.new(search_attribute, options, &block)
            end
          end
        
        
          # define search attributes from builders
        
          search_attributes_builders.each do |builder|
            rewrite_search_attribute_builder(builder)
            add_search_attribute(builder)
          end
        
          nil # don't pollute class creation
        end


        # Returns an unordered Array of all search attributes defined through search_accessor.
        #
        # Example:
        #   class StuffSearch < SearchApi::Search::Base
        #     search_accessor :search_key1, :search_key2
        #   end
        #
        #   StuffSearch.search_attributes # => [:search_key1, :search_key2]
        def search_attributes
          read_inheritable_attribute(:search_attributes) || []
        end
      
        protected
      
        # <b>Unless you're an SearchApi::Bridge::Base subclass designer, you should use
        # search_accessor method instead.</b>
        # 
        # search_attribute_builder is a SearchAttributeBuilder instance.
        #
        # This methods adds a search attribute to that SearchApi::Search::Base class:
        # - search_attribute_builder.name is the name of the search attribute,
        # - search_attribute_builder.options are options for defining the
        #   search attribute,
        # - search_attribute_builder.block is an optional proc that implement
        #   the search attribute behavior.
        #
        # search_attribute_builder.options keys must be in VALID_SEARCH_ATTRIBUTE_OPTIONS.
        #
        # Adding a search attributes, precisely, means:
        #
        # - A writer, a reader, an interrogation reader, and a ignored reader are defined.
        #
        #   Writer and reader act as usual. Interrogation reader acts as ActiveRecord::Base's one.
        #
        #   Ignorer reader tells whether the search attribute is ignored or not.
        # 
        #     # Defines following StuffSearch instance methods:
        #     # - :a,
        #     # - :a=
        #     # - :a?
        #     # - :a_ignored?
        #     class StuffSearch < SearchApi::Search::Base
        #       model Stuff
        #       add_search_attribute(SearchApi::Search::SearchAttributeBuilder.new(:a))
        #     end
        #
        # - The method <tt>find_options_for_[search attribute]</tt> is defined,
        #   if the builder's block is set.
        #
        #   That block takes a single parameter: a SearchApi::Search::Base instance. Its result
        #   should be enough to define a model search.
        #
        #   In case of ActiveRecord models, it should be a valid Hash that can be used as
        #   ActiveRecord::Base.find argument.
        # 
        #     # Defines following StuffSearch instance methods:
        #     # - :a,
        #     # - :a=
        #     # - :a?
        #     # - :a_ignored?
        #     # - :find_options_for_a
        #     class StuffSearch < SearchApi::Search::Base
        #       model Stuff
        #       add_search_attribute(SearchApi::Search::SearchAttributeBuilder.new(:max_age)) do |search|
        #         { :conditions => ['birth_date > ?', Time.now - search.max_age.years]}
        #       end
        #     end
        #
        # You can avoid defining the builder's block, and define the
        # <tt>find_options_for_[search attribute]</tt> method yourself.
        #
        #   class StuffSearch < SearchApi::Search::Base
        #     model Stuff
        #     add_search_attribute(SearchApi::Search::SearchAttributeBuilder.new(:max_age))
        #     def find_options_for_max_age
        #       { :conditions => ['birth_date > ?', Time.now - max_age.years]}
        #     end
        #   end
        def add_search_attribute(search_attribute_builder)
          search_attribute =  search_attribute_builder.name
          options =           search_attribute_builder.options
          block =             search_attribute_builder.block


          # check options
          options ||= {}
          invalid_options = options.keys - VALID_SEARCH_ATTRIBUTE_OPTIONS
          raise ArgumentError.new("invalid options #{invalid_options.inspect}") unless invalid_options.empty?


          # fill search_attributes array
          write_inheritable_array(:search_attributes, [search_attribute])
        
        
          # store default value
          options[:default] ||= SearchApi::Search.ignored
          write_inheritable_hash(:search_attribute_default_values, { search_attribute => options[:default]})
        

          # define reader
          attr_reader search_attribute


          # define writer
          if store_as_proc = options[:store_as]
            define_method("#{search_attribute}=") do |value|
              instance_variable_set("@#{search_attribute}", if SearchApi::Search.ignored?(value) then value else store_as_proc.call(value) end)
            end
          else
            attr_writer search_attribute
          end


          # define interrogation reader
          define_method("#{search_attribute}?") do
            !!send(search_attribute)
          end


          # define ignored reader
          define_method("#{search_attribute}_ignored?") do
            SearchApi::Search.ignored?(send(search_attribute))
          end


          # Define find_options_for_xxx method
          if block
            # user-defined method
            define_method("find_options_for_#{search_attribute}") do
              if SearchApi::Search.ignored?(send(search_attribute))
                {}
              else
                block.call(self)
              end
            end
          end
        end


        private
      
        # Adds search accessors for automatic attributes
        def add_automatic_search_attributes(options)  #:nodoc:
          # define a search attribute for each automatic search attribute
          model.
            search_api_bridge.
            automatic_search_attribute_builders(options).
            each do |builder|
              search_accessor(builder)
            end
        end
      
      
        # Rewrites a SearchAttributeBuilder.
        #
        # On output, search_attribute_builder should be a valid 
        # SearchApi::Search::Base.add_search_attribute argument.
        def rewrite_search_attribute_builder(search_attribute_builder)
          model.search_api_bridge.rewrite_search_attribute_builder(search_attribute_builder) if model
        end
      
      
      end
    
  
      # Initializes a search with a search attributes Hash.
      def initialize(attributes=nil)
        raise "Can't create an instance without model" if self.class.model.nil?
      
        # initialize attributes with ignored value
        self.attributes = self.class.search_attributes.inject((attributes || {}).dup) do |attributes, search_attribute|
          if attributes.has_key?(search_attribute) || attributes.has_key?(search_attribute.to_s)
            attributes
          else
            attributes.update(search_attribute => self.class.read_inheritable_attribute(:search_attribute_default_values)[search_attribute])
          end
        end
      end
    
    
    
      # Returns a Hash of search attributes.
      def attributes
        self.class.search_attributes.inject({}) do |attributes, search_attribute|
          attributes.update(search_attribute => send(search_attribute))
        end
      end
    
      # Sets search attributes via a Hash
      def attributes=(attributes=nil)
        (attributes || {}).each do |search_attribute, value|
          send("#{search_attribute}=", value)
        end
      end
    
    
      # Returns whether search_attribute is ignored.
      def ignored?(search_attribute)
        SearchApi::Search.ignored?(send(search_attribute))
      end

      # Ignore given search_attribute.
      def ignore!(search_attribute)
        send("#{search_attribute}=", SearchApi::Search.ignored)
      end
    
    
    
      # Returns an object that should be enough to define a model search.
      #
      # In case of ActiveRecord models, returns a valid Hash that can be used as
      # ActiveRecord::Base.find argument.
      def find_options
        # collect all find_options for not ignored attributes
      
        options_array = self.class.search_attributes.
      
          # reject ignored attributes
          reject { |search_attribute| ignored?(search_attribute) }.

          # merge options for all attributes
          map { |search_attribute| send("find_options_for_#{search_attribute}") }

                          
        # merge them options for not ignored attributes
      
        self.class.model.search_api_bridge.merge_find_options(options_array)
      end
    
    
      protected
    
      def find_options_for_hash(conditions) #:nodoc:
        # merge options for not ignored attributes
        model.
          search_api_bridge.
          merge_find_options(
          )
        conditions.
      
          # reject ignored attributes
          reject { |search_attribute, value| SearchApi::Search.ignored?(value) }.
        
          # merge options for all attributes
          map do |search_attribute, value|
            send("find_options_for_#{search_attribute}")
          end
      end
    end

    protected
  
    # Describes a search attribute with:
    # - a name,
    # - some options
    # - an optional block
    class SearchAttributeBuilder
      # name is a search attribute name. It is read-only so that SearchApi::Bridge::Base.rewrite_search_attribute_builder is unable to rename attributes.
      attr_reader :name

      # options is an options Hash (never nil, may be empty Hash)
      attr_accessor :options

      # block is an optional proc (may be nil)
      attr_accessor :block
    
      def initialize(name, options={}, &block)
        @name = name.to_sym
        @options = options
        @block = block
      end
    end
  
    # Class of values ignored by Search instances.
    class IgnoredValue
      def inspect #:nodoc:
        "<ignored>"
      end
    end

    class << self
    
      def ignored #:nodoc:
        @ignore ||= IgnoredValue.new
      end
  
      def ignored?(value) #:nodoc:
        value.is_a? IgnoredValue
      end
    end

  end
end
