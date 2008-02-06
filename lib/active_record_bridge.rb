require 'search_api'

module SearchApi
  module Bridge

    # SearchApi::Bridge::Base subclass that allows ActiveRecord to be used with SearchApi::Search::Base.
  
    class ActiveRecord < Base

      # Operators that apply on a single column.
      SINGLE_COLUMN_OPERATORS = %w(eq neq lt lte gt gte contains starts_with ends_with)
    
      # Operators that apply on several columns.
      MULTI_COLUMN_OPERATORS = %w(full_text)
    
      class << self
        VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :order, :select, :group, :having ]

        def validate_find_options(options) #:nodoc:
          options.assert_valid_keys(VALID_FIND_OPTIONS)
        end
      end
    
      # store the active_record_subclass
      def initialize(active_record_subclass) #:nodoc:
        @active_record_class = active_record_subclass
      end
    
      # This method is called when a SearchApi::Search::Base's model is set,
      # in order to predefine some relevant search keys.
      #
      # Returns an Array of SearchApi::Search::SearchAttributeBuilder instances.
      #
      # Each builder can be used as an argument for SearchApi::Search::Base.search_accessor.
      #
      # In the contexte of ActiveRecord:
      # - each columns defines at least one search attribute, the obvious
      #   equality search attribute.
      #
      #   With the same name as the column, it has the exact same behavior as
      #   the standard <tt>AR::Base.find(:all, :conditions => {column => value})</tt>.
      #   
      # - each comparable column defines a lower and an upper-bound search attribute,
      #   named min_xxx and max_xxx when xxx is the column name.
      #
      #
      # Valid options are:
      # - <tt>:type_cast</tt> - default false: when true, returned builders will
      #   use the <tt>:store_as</tt> option in order to type cast search attributes
      #   according to column type.
      #
      # 
      # Example
      #
      #   class Search1 < SearchApi::Search::Base
      #     model Searchable
      #   end
      #   
      #   class Search2 < SearchApi::Search::Base
      #     model Searchable, :type_cast => true
      #   end
      #   
      #   search1 = Search1.new
      #   search2 = Search2.new
      #   
      #   search1.id = search2.id = '12'
      #   search1.id => '12'       # no type cast
      #   search2.id => 12         # type cast in action
      #   
      #   search1.min_id = search2.min_id = '12'  # OK, predefined search attribute for numeric column
      #   search1.max_id = search2.max_id = '12'  # OK, predefined search attribute for numeric column
    
      def automatic_search_attribute_builders(options)
      
        # every column will create builders
        builders = []
        @active_record_class.columns.each do |column|
        
          # Append a builder for a standard AR::Base search.
          builders << ::SearchApi::Search::SearchAttributeBuilder.new(
                        column.name,                          # search attribute name is the column name,
                        :type_cast => options[:type_cast],    # type cast if required,
                        :column => column.name,               # look in to that very column...
                        :operator => :eq)                     # ... for equality
        
          # Create extra builders for comparable columns
          if column.klass < Comparable
            # Builder for a lower-bound search
            builders << ::SearchApi::Search::SearchAttributeBuilder.new(
                          "min_#{column.name}",               # search attribute name is min_column name,
                          :type_cast => options[:type_cast],  # type cast if required,
                          :column => column.name,             # look in to that very column...
                          :operator => :gte)                  # ... for values greater or equal to lower bound

            # Builder for a upper-bound search
            builders << ::SearchApi::Search::SearchAttributeBuilder.new(
                          "max_#{column.name}",               # search attribute name is max_column name,
                          :type_cast => options[:type_cast],  # type cast if required,
                          :column => column.name,             # look in to that very column...
                          :operator => :lte)                  # ... for values lower or equal to upper bound
          end
        end
        builders
      end


      # This method is called when a SearchApi::Search::Base.search_accessor is
      # called, to help you implementing some usual ActiveRecord searches.
      #
      # Modifies in place a SearchApi::Search::SearchAttributeBuilder.
      #
      # On output, search_attribute_builder should be a valid 
      # SearchApi::Search::Base.add_search_attribute argument.
      #
      # You may provide an <tt>:operator</tt> option.
      #
      # Some apply on a single column, other on several ones.
      #
      # Single-column operator are:
      # - <tt>:eq</tt> - equality operator.
      #
      #   It has the exact same behavior as the standard
      #   <tt>AR::Base.find(:all, :conditions => {column => value})</tt>.
      #
      # - <tt>:neq</tt> - inequality operator
      # - <tt>:lt</tt> - "lower than" operator
      # - <tt>:lte</tt> - "lower than or equal" operator
      # - <tt>:gt</tt> - "greater than" operator
      # - <tt>:gte</tt> - "greater than or equal" operator
      # - <tt>:contains</tt> - uses LIKE sql operator
      # - <tt>:starts_with</tt> - uses LIKE sql operator
      # - <tt>:ends_with</tt> - uses LIKE sql operator
      #
      # Multi-column operators are:
      # - <tt>:full_text</tt> - full text search
      #
      # Those operators require some other options:
      # - <tt>:column</tt> - required by single column operator
      # - <tt>:columns</tt> - required by multi column operator
      # - <tt>:type_cast</tt> - optional for single column operators, default false.
      #   When true, search_attribute_builder is rewritten so that its
      #   <tt>:store_as</tt> option casts incoming values according to column type.
      def rewrite_search_attribute_builder(search_attribute_builder)
        # consume :operator option
        operator = search_attribute_builder.options.delete(:operator)
        return unless operator
      
        if SINGLE_COLUMN_OPERATORS.include?(operator.to_s)

          search_attribute = search_attribute_builder.name
          options = search_attribute_builder.options

          # consume :column option
          column_name = options.delete(:column)
          raise ArgumentError.new("#{operator} operator requires the :column options to contain a column name.") unless column_name && !column_name.is_a?(Array)
        
          # we'll use that column name everywhere
          sql_column_name = "#{@active_record_class.table_name}.#{@active_record_class.connection.quote_column_name(column_name)}"
        
          # consume :type_cast option
          if options.delete(:type_cast)
            @active_record_instance ||= @active_record_class.new
            # §§§ what if :store_as option is already defined ?
            options[:store_as] = proc do |value|
              @active_record_instance.send("#{column_name}=", value)
              @active_record_instance.send(column_name)
            end
          end

          # block rewriting
          case operator
          when :eq
            search_attribute_builder.block = proc do |search|
              { :conditions => search.class.model.send(:sanitize_sql_hash, column_name => search.send(search_attribute)) }
            end

          when :neq
            # §§§ some work is necessary on boolean columns
            search_attribute_builder.block = proc do |search|
              case value = search.send(search_attribute)
              when nil
                { :conditions => "#{sql_column_name} IS NOT NULL" }
              else
                { :conditions => ["#{sql_column_name} <> ? OR #{sql_column_name} IS NULL", value] }
              end
            end

          when :lt
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute)
              { :conditions => ["#{sql_column_name} < ?", value] } unless value.nil?
            end

          when :lte
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute)
              { :conditions => ["#{sql_column_name} <= ?", value] } unless value.nil?
            end

          when :gt
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute)
              { :conditions => ["#{sql_column_name} > ?", value] } unless value.nil?
            end

          when :gte
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute)
              { :conditions => ["#{sql_column_name} >= ?", value] } unless value.nil?
            end

          when :contains
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute).to_s
              { :conditions => ["#{sql_column_name} LIKE ?", "%#{value}%"] } unless value.empty?
            end

          when :starts_with
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute).to_s
              { :conditions => ["#{sql_column_name} LIKE ?", "#{search.send(search_attribute)}%"] } unless value.empty?
            end

          when :ends_with
            search_attribute_builder.block = proc do |search|
              value = search.send(search_attribute).to_s
              { :conditions => ["#{sql_column_name} LIKE ?", "%#{search.send(search_attribute)}"] } unless value.empty?
            end
          end

        elsif MULTI_COLUMN_OPERATORS.include?(operator.to_s)

          search_attribute = search_attribute_builder.name
          options = search_attribute_builder.options

          # consume :columns || :column option
          column_names = Array(options.delete(:columns) || options.delete(:column))
          raise ArgumentError.new("#{operator} operator requires the :column or :columns options to contain column names.") if column_names.empty?
        
          # we'll use that column names everywhere
          sql_column_names = column_names.map do |column_name|
            "#{@active_record_class.table_name}.#{@active_record_class.connection.quote_column_name(column_name)}"
          end

          case operator
          when :full_text
            # We'll use TextCriterion class.
          
            # consume :exclude option
            exclude = options.delete(:exclude) || /^[^0-9].{0,2}$/

            search_attribute_builder.block = lambda do |search|
              value = search.send(search_attribute).to_s
              { :conditions => TextCriterion.new(value, :exclude => exclude).condition(sql_column_names) } unless value.empty?
            end
          end
        else
          raise ArgumentError.new("Unknown operator #{operator}")
        end
      end
    
      # Overrides default Bridge::Base.merge_find_options.
      # 
      # This methods returns a merge of options in options_array.
      def merge_find_options(options_array)
        all_options = options_array.compact.inject({}) do |all_options, options|
          self.class.validate_find_options(options)
          options.each do |key, value|
            next if value.blank? || (value.respond_to?(:empty?) && value.empty?)
            (all_options[key] ||= []) << value
          end
          all_options
        end
      
      
        merged_options = {}
      
      
        # Merge :conditions options
      
        unless all_options[:conditions].nil? || all_options[:conditions].empty?
          # merge conditions with AND
          merged_options[:conditions] = '(' + all_options[:conditions].
                                                map { |fragment| SearchApi::SqlFragment.sanitize(fragment) }.
                                                uniq.
                                                join(") AND (")+ ')'
        end
      
      
        # Merge :include options
      
        unless all_options[:include].nil? || all_options[:include].empty?
          # merge includes with set-union
          merged_options[:include] = all_options[:include].inject([]) { |merged_includes, include_options| merged_includes |= Array(include_options) }
        end
      
      
        # Merge :joins options
      
        unless all_options[:joins].nil? || all_options[:joins].empty?
          # merge joins with space
          merged_options[:joins] = all_options[:joins].
                                                map { |fragment| SearchApi::SqlFragment.sanitize(fragment) }.
                                                uniq.
                                                join(' ')
        end
      
      
        # Merge :group and :having options
      
        unless all_options[:having].nil? || all_options[:having].empty?
          # default group by if having clause is present
          if all_options[:group].nil? || all_options[:group].empty?
            all_options[:group] = ["#{@active_record_class.table_name}.#{@active_record_class.primary_key}"]
          end
        end
        
        unless all_options[:group].nil? || all_options[:group].empty?
          # merge groups with comma
          merged_options[:group] = all_options[:group].
                                                map { |fragment| SearchApi::SqlFragment.sanitize(fragment) }.
                                                uniq.
                                                join(', ')
        
          # merge having conditions into :group option
          unless all_options[:having].nil? || all_options[:having].empty?
            # merge having with AND
            merged_options[:group] += ' HAVING (' + all_options[:having].
                                                    map { |fragment| SearchApi::SqlFragment.sanitize(fragment) }.
                                                    uniq.
                                                    join(') AND (')+ ')'
          end
        end
      
      
        # Merge :order options
      
        unless all_options[:order].nil? || all_options[:order].empty?
          # merge order with comma
          merged_options[:order] = all_options[:order].
                                                map { |fragment| SearchApi::SqlFragment.sanitize(fragment) }.
                                                join(', ')
        end
      
      
        # Merge :select options
      
        unless all_options[:select].nil? || all_options[:select].empty?
          # merge select with comma
          merged_options[:select] = all_options[:select].
                                                map { |fragment| SearchApi::SqlFragment.sanitize(fragment) }.
                                                uniq.
                                                join(', ')
        end
      
        if merged_options[:joins] && merged_options[:select].nil?
          # since joins add columns, restrict default column set to base class columns
          merged_options[:select] = "DISTINCT #{@active_record_class.table_name}.*"
        end
      
      
        # merged_options is now ready for ActiveRecord::Base
      
        merged_options
      end
    end

  end
end


class ActiveRecord::Base
  class << self
    
    # Returns an SearchApi::Bridge::ActiveRecord instance.
    #
    # The presence of this method allows ActiveRecord::Base subclasses
    # to be used as models by SearchApi::Search::Base subclasses.
    def search_api_bridge
      SearchApi::Bridge::ActiveRecord.new(self)
    end
  end
end
