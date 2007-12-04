class Searchable < ActiveRecord::Base
end


# bridge for testing of SearchAttributeBuilder rewriting
class RewriterBridge < SearchApi::Bridge::Base
  def rewrite_search_attribute_builder(search_attribute_builder)
    search_attribute_builder.options = { :store_as => proc do |x| x.to_i + 1 end }
    search_attribute_builder.block = proc do |search| search.send(search_attribute_builder.name)+1 end
  end
end

# model using RewriterBridge
class ModelWithRewriterBridge
  class << self
    def search_api_bridge
      RewriterBridge.new
    end
  end
end


# bridge for testing of automatic search attributes
class AutomaticBridge < SearchApi::Bridge::Base
  def automatic_search_attribute_builders(options)
    [SearchApi::Search::SearchAttributeBuilder.new(:a) do |search| search.a.succ end]
  end
end

# model using AutomaticBridge
class ModelWithAutomaticBridge
  class << self
    def search_api_bridge
      AutomaticBridge.new
    end
  end
end


# bridge for testing of find options merging
class MergerBridge < SearchApi::Bridge::Base
  def merge_find_options(options_array)
    options_array.inject(0) { |sum, x| sum + x}
  end
end

# model using MergerBridge
class ModelWithMergerBridge
  class << self
    def search_api_bridge
      MergerBridge.new
    end
  end
end
