require 'test/unit'
RAILS_ENV = "test"
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'search_api'
require 'active_record_bridge'
require 'active_record_integration'
require 'test/mock_model'

class ActiveRecordIntegrationTest < Test::Unit::TestCase
  
  def setup
    begin
      Searchable.find(:first)
    rescue
      raise "run 'rake search_api_migrate_test_db' in the application directory before running search_api tests"
    end
  end
  
  def test_integration
    Searchable.class_eval do
      has_search_api
      
      search :old do |search|
        if search.old
          { :conditions => ['age > 80'] }
        else
          { :conditions => ['age < 80'] }
        end
      end
    end
    

    assert_equivalent_request({:conditions => 'age > 80'},
                              {:conditions => {:old => true}})
    
    assert_equivalent_request({:conditions => 'age < 80'},
                              {:conditions => {:old => false}})
    
  end
  
  protected
  
  def assert_equivalent_request(traditional_find_options, search_options)
    traditional_result_ids = Searchable.find(:all, traditional_find_options).map(&:id).sort
    search_result_ids = Searchable.find(:all, search_options).map(&:id).sort
    assert !traditional_result_ids.empty?
    assert_equal traditional_result_ids, search_result_ids
  end
end
