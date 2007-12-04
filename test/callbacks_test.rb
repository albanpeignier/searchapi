require 'test/unit'
RAILS_ENV = "test"
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'search_api'
require 'active_record_bridge'
require 'test/mock_model'

class CallbacksTest < Test::Unit::TestCase
  def test_before_find_options_method
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    search_class.class_eval do
      model Searchable
    end

    # get some attributes that fills some find_options (should we test the test ?)
    assert_not_equal search_class.new.find_options, search_class.new(:age=>12).find_options

    # reopen the search class
    search_class.class_eval do
      def before_find_options
        self.class.search_attributes.each do |search_attribute|
          ignore!(search_attribute)
        end
      end
    end

    # those same attributes should now be ignored
    assert_equal search_class.new.find_options, search_class.new(:age=>12).find_options
  end


  def test_before_find_options_symbol
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    search_class.class_eval do
      model Searchable
    end

    # get some attributes that fills some find_options (should we test the test ?)
    assert_not_equal search_class.new.find_options, search_class.new(:age=>12).find_options

    # reopen the search class
    search_class.class_eval do
      before_find_options :ignore_all_attributes
        
      def ignore_all_attributes
        self.class.search_attributes.each do |search_attribute|
          ignore!(search_attribute)
        end
      end
    end

    # those same attributes should now be ignored
    assert_equal search_class.new.find_options, search_class.new(:age=>12).find_options
  end


  def test_before_find_options_symbol
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    search_class.class_eval do
      model Searchable
    end

    # get some attributes that fills some find_options (should we test the test ?)
    assert_not_equal search_class.new.find_options, search_class.new(:age=>12).find_options

    # reopen the search class
    search_class.class_eval do
      before_find_options "self.ignore_all_attributes"
        
      def ignore_all_attributes
        self.class.search_attributes.each do |search_attribute|
          ignore!(search_attribute)
        end
      end
    end

    # those same attributes should now be ignored
    assert_equal search_class.new.find_options, search_class.new(:age=>12).find_options
  end


  def test_before_find_options_proc
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    search_class.class_eval do
      model Searchable
    end

    # get some attributes that fills some find_options (should we test the test ?)
    assert_not_equal search_class.new.find_options, search_class.new(:age=>12).find_options

    # reopen the search class
    search_class.class_eval do
      before_find_options { |search| search.ignore_all_attributes }
        
      def ignore_all_attributes
        self.class.search_attributes.each do |search_attribute|
          ignore!(search_attribute)
        end
      end
    end

    # those same attributes should now be ignored
    assert_equal search_class.new.find_options, search_class.new(:age=>12).find_options
  end


  class BlackHole
    # ignore all attributes of search
    def before_find_options(search)
      search.class.search_attributes.each do |search_attribute|
        search.ignore!(search_attribute)
      end
    end
  end
  
  def test_before_find_options_object
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    search_class.class_eval do
      model Searchable
    end

    # get some attributes that fills some find_options (should we test the test ?)
    assert_not_equal search_class.new.find_options, search_class.new(:age=>12).find_options

    # reopen the search class
    search_class.class_eval do
      before_find_options BlackHole.new
    end

    # those same attributes should now be ignored
    assert_equal search_class.new.find_options, search_class.new(:age=>12).find_options
  end
  
  def test_bad_before_find_options
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    search_class.class_eval do
      model Searchable
      before_find_options 1
    end

    assert_raise SearchApi::SearchApiError do
      search_class.new.find_options
    end
  end
end
