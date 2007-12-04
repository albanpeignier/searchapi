module SearchApi

  # Module that holds SearchApi::Bridge::Base and its default subclasses.
  module Bridge
    
    # Base class for SearchApi bridges.
    #
    # Such a bridge have following responsabilities:
    #
    # - <b>predefining search attributes</b>, when the model of a SearchApi::Search::Base
    #   subclass is set.
    #
    #   This is done by the automatic_search_attribute_builders method.
    #
    # - <b>rewriting SearchAttributeBuilder instances</b>.
    #
    #   The SearchApi::Search::Base class defines a generic, dull, way to define search attributes.
    #
    #   Precisely speaking, the SearchApi::Search::Base.add_search_attribute method,
    #   the one that actually defines search attributes, has strong
    #   requirements on its SearchAttributeBuilder parameter.
    #
    #   A bridge is able to define a domain-specific way to define search
    #   attributes. This is the bridge's reponsability
    #   to translate these domain-specific SearchAttributeBuilder instances
    #   into strict SearchAttributeBuilder instances, that
    #   SearchApi::Search::Base.add_search_attribute can use.
    #
    #   This is done by the rewrite_search_attribute_builder method.
    #
    # - <b>merging find options</b>, in order to build a single option from
    #   those built by several search attributes.
    #
    #   This is done by the merge_find_options method.

    class Base
    
      # This method is called when a SearchApi::Search::Base's model is set, in order to
      # predefine some relevant search keys.
      #
      # Returns an Array of SearchAttributeBuilder instances.
      #
      # Each builder can be used as an argument for SearchApi::Search::Base.search_accessor.
      #
      # Default SearchApi::Bridge::Base behavior is to return an empty Array: there is no
      # automatic search attributes by default.
      def automatic_search_attribute_builders(options)
        []
      end
    
    
      # This method is called when a SearchApi::Search::Base.search_accessor is
      # called, to allow SearchApi::Bridge::Base subclasses to handle special builder options.
      #
      # Rewrites a SearchAttributeBuilder.
      #
      # On output, search_attribute_builder should be a valid 
      # SearchApi::Search::Base.add_search_attribute argument.
      #
      # Default SearchApi::Bridge::Base behavior is to leave the builder untouched.
      #
      # Subclasses may take the chance to use some specific options.
      def rewrite_search_attribute_builder(search_attribute_builder)
      end
    
    
      # This methods returns a merge of options in options_array.
      #
      # Default SearchApi::Bridge::Base behavior is to raise NotImplementedError.
      def merge_find_options(options_array)
        raise NotImplementedError.new
      end
    end
  end
end