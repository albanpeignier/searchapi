require 'test/unit'
RAILS_ENV = "test" unless defined?(RAILS_ENV)
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'search_api'
require 'active_record_bridge'
require 'test/mock_model'

class BridgteTest < Test::Unit::TestCase
  def test_rewriter_bridge
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    assert_nothing_raised do
      search_class.class_eval do
        model ModelWithRewriterBridge
        search_accessor :a, :b
      end
    end
    
    # assert accessors are there, and store_as option is active
    search = search_class.new(:a => '1', :b=>'2')
    assert_equal 2, search.a
    assert_equal 3, search.b
    
    # assert find_options_for_xxx exist, and behave correctly
    assert_equal 3, search.find_options_for_a
    assert_equal 4, search.find_options_for_b
  end

  def test_automatic_bridge
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    assert_nothing_raised do
      search_class.class_eval do
        model ModelWithAutomaticBridge
      end
    end
    
    # assert automatic search attributes are there
    assert_equal [:a], search_class.search_attributes.sort
    
    # assert accessors are there
    search = search_class.new(:a => 'a')
    assert_equal 'a', search.a
    
    # assert find_options_for_a exists, and behaves correctly
    assert_equal 'b', search.find_options_for_a
  end

  def test_merger_bridge
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    assert_nothing_raised do
      search_class.class_eval do
        model ModelWithMergerBridge
        search_accessor :a do |search| search.a end
        search_accessor :b do |search| search.b end
      end
    end

    # assert accessors are there, and store_as option is active
    search = search_class.new(:a => 1, :b=>2)
    assert_equal 3, search.find_options
  end

end

