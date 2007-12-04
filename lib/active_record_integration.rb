require 'search_api'

module SearchApi
  
  # Module that holds SearchApi integration patterns.
  module Integration
    
    # Module that holds integration of SearchApi into ActiveRecord.
    module ActiveRecord

      # This module allows the ActiveRecord::Base classes to transparently
      # integrate SearchApi::Search::Base features.
      #
      # It is included in a ActiveRecord::Base subclass by calling has_search_api:
      #
      #   class People < ActiveRecord::Base
      #     has_search_api
      #   
      #     # define age search key
      #     search :age do |search|
      #       { :conditions => ['birth_date BETWEEN ? AND ?',
      #                         (Date.today-search.age.years),
      #                         (Date.today-(search.age-1).years+1.day)]}
      #     end
      #   end
      #
      #   People.find(:all, :conditions => {:first_name => 'Roger', :age => 30})
      
      module Base
        # Modifies the class including that module so that :find, :count and :with_scope
        # methods have support for search keys added by the search method.
        #
        # <b>Don't include yourself this module !</b> Instead, use
        # ActiveRecord::Base.has_search_api method.
        def self.append_features(base)
          super
          base.alias_method_chain(:find, :search_support)
          base.alias_method_chain(:count, :search_support)
          base.alias_method_chain(:with_scope, :search_support)
        end
    
        # Alteration of the :find method that has support for search keys added by the search method.
        def find_with_search_support(*args)
          options = if args.last.is_a?(Hash) then args.last else {} end
          if options[:conditions].nil? || options[:conditions].is_a?(Hash)
            with_scope(:find => search_class.new(options.delete(:conditions)).find_options) do
              find_without_search_support(*args)
            end
          else
            find_without_search_support(*args)
          end
        end

        # Alteration of the :count method that has support for search keys added by the search method.
        def count_with_search_support(*args)
          options = if args.last.is_a?(Hash) then args.last else {} end
          if options[:conditions].nil? || options[:conditions].is_a?(Hash)
            with_scope(:find => search_class.new(options.delete(:conditions)).find_options) do
              count_without_search_support(*args)
            end
          else
            count_without_search_support(*args)
          end
        end

        # Alteration of the :with_scope method that has support for search keys added by the search method.
        def with_scope_with_search_support(method_scoping = {}, action = :merge, &block)
          if method_scoping[:find] && method_scoping[:find][:conditions] && method_scoping[:find][:conditions].is_a?(Hash)
            with_scope_without_search_support(:find => search_class.new(method_scoping[:find].delete(:conditions)).find_options) do
              with_scope_without_search_support(method_scoping, action, &block)
            end
          else
            with_scope_without_search_support(method_scoping, action, &block)
          end
        end
        
        # Extends the keys that conditions hashes can hold.
        #
        # ActiveRecord::Base.find can take a <tt>:conditions</tt> option. This option
        # can be raw SQL, a SQL fragment such as <tt>['a=?',1]</tt>, or a condition hash
        # such as <tt>{:column1 => value, ;column2 => value}</tt>.
        #
        # <b>The search method allows you to extend the keys that condition hash
        # can hold.</b>
        #
        # For instance, assuming a :birth_date column exists in your table, you
        # can define the :age search key:
        #
        #   class People < ActiveRecord::Base
        #     has_search_api
        #   
        #     # define age search key
        #     search :age do |search|
        #       { :conditions => ['birth_date BETWEEN ? AND ?',
        #                         (Date.today-search.age.years),
        #                         (Date.today-(search.age-1).years+1.day)]}
        #     end
        #   end
        #
        # The options parameter allows you to define some search keys without
        # providing a block:
        #
        #   class People < ActiveRecord::Base
        #     has_search_api
        #   
        #     search :keyword, :operator => :full_text, :columns => [:first_name, :last_name, :email]
        #     search :email_domain, :operator => :ends_with, :column => :email
        #   end
        #
        # For further details, see:
        # - how search attributes are defined: SearchApi::Search::Base.search_accessor;
        # - which options are understood: SearchApi::Bridge::ActiveRecord#rewrite_search_attribute_builder method.
        def search(name, options={}, &block)
          search_class.search_accessor(name, options, &block)
        end
      end
        

      # This module allows the ActiveRecord::Base associations to transparently
      # integrate SearchApi::Search::Base features.
      #
      #   class People < ActiveRecord::Base
      #     belongs_to :company
      #     has_search_api
      #   
      #     # define age search key
      #     search :age do |search|
      #       { :conditions => ['birth_date BETWEEN ? AND ?',
      #                         (Date.today-search.age.years),
      #                         (Date.today-(search.age-1).years+1.day)]}
      #     end
      #   end
      #
      #   some_company.people.find(:all, :conditions => {:first_name => 'Roger', :age => 30})
      module Associations

        # Module that holds integration of SearchApi::Search::Base into
        # ActiveRecord::Associations::HasManyAssociation,
        # ActiveRecord::Associations::HasAndBelongsToManyAssociation, and
        # ActiveRecord::Associations::HasManyThroughAssociation.
        module Find
          def self.append_features(base) #:nodoc:
            super
            base.alias_method_chain(:find, :search_support)
          end

          # Alteration of the :find method that has support for search keys added by the search method.
          def find_with_search_support(*args)
            if @reflection.klass.respond_to?(:search_class)
              options = if args.last.is_a?(Hash) then args.last else {} end
              if options[:conditions].nil? || options[:conditions].is_a?(Hash)
                @reflection.klass.with_scope(:find => @reflection.klass.search_class.new(options.delete(:conditions)).find_options) do
                  find_without_search_support(*args)
                end
              else
                find_without_search_support(*args)
              end
            else
              find_without_search_support(*args)
            end
          end
        end

        # Module that holds integration of SearchApi::Search::Base into ActiveRecord::Associations::HasManyAssociation.
        module Count
          def self.append_features(base) #:nodoc:
            super
            base.alias_method_chain(:count, :search_support)
          end

          # Alteration of the :count method that has support for search keys added by the search method.
          def count_with_search_support(*args)
            if @reflection.klass.respond_to?(:search_class)
              options = if args.last.is_a?(Hash) then args.last else {} end
              if options[:conditions].nil? || options[:conditions].is_a?(Hash)
                @reflection.klass.with_scope(:find => @reflection.klass.search_class.new(options.delete(:conditions)).find_options) do
                  count_without_search_support(*args)
                end
              else
                count_without_search_support(*args)
              end
            else
              count_without_search_support(*args)
            end
          end
        end
      end
    end
  end
end


class ActiveRecord::Base
  class << self
    
    # This method has following consequences:
    #
    # - The ActiveRecord::Base class is made searchable.
    #
    #   Practically speaking, a SearchApi::Search::Base subclass that targets
    #   this model is created, prefilled with many automatic search keys
    #   (see SearchApi::Bridge::ActiveRecord).
    #
    # - The ActiveRecord::Base class is able to define its own condition hash keys.
    #
    #   Practically speaking, the SearchApi::Integration::ActiveRecord::Base
    #   methods are included, and specifically its <tt>search</tt> method that allows to
    #   define custom keys for condition hashes.
    #
    # Example:
    #
    #   class People < ActiveRecord::Base
    #     has_search_api
    #   
    #     # define age search key
    #     search :age do |search|
    #       { :conditions => ['birth_date BETWEEN ? AND ?',
    #                         (Date.today-search.age.years),
    #                         (Date.today-(search.age-1).years+1.day)]}
    #     end
    #   end
    #
    #   People.search_class # => the SearchApi::Search::Base subclass for People.
    #   People.find(:all, :conditions => { :age => 30 })
    #
    # Optional block is for advanced purpose only. It is executed as a
    # <tt>class_eval</tt> block for the SearchApi::Search::Base subclass.
    #
    #   class People < ActiveRecord::Base
    #     has_search_api do
    #       ...
    #     end
    #   end
    def has_search_api(&block) # :yields:
      # Creates a new SearchApi::Search::Base subclass
      search_class = Class.new(::SearchApi::Search::Base)
      
      # Tells the SearchApi::Search::Base subclass which models it searches in
      search_class.model(self, :type_cast=>true)
      
      # Let given block define search keys
      search_class.class_eval(&block) if block
            
      (class << self; self; end).instance_eval do
        # The search_class method returns the SearchApi::Search::Base subclass.
        define_method(:search_class) { search_class }
        
        # Alter class behavior so that the SearchApi::Search::Base subclass seemlessly integrates.
        include ::SearchApi::Integration::ActiveRecord::Base
      end
      
      nil # don't pollute class creation
    end
  end
end


# Modify associations behaviors

ActiveRecord::Associations::HasManyAssociation.module_eval do
  include ::SearchApi::Integration::ActiveRecord::Associations::Find
  include ::SearchApi::Integration::ActiveRecord::Associations::Count
end

ActiveRecord::Associations::HasAndBelongsToManyAssociation.module_eval do
  include ::SearchApi::Integration::ActiveRecord::Associations::Find
end

ActiveRecord::Associations::HasManyThroughAssociation.module_eval do
  include ::SearchApi::Integration::ActiveRecord::Associations::Find
end

