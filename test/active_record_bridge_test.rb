require 'test/unit'
RAILS_ENV = "test"
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'search_api'
require 'active_record_bridge'
require 'test/mock_model'

class ActiveRecordBridgeTest < Test::Unit::TestCase
  
  def setup
    begin
      Searchable.find(:first)
    rescue
      raise "run 'rake searchapi_migrate_test_db' in the application directory before running searchapi tests"
    end
  end
  
  
  def test_active_record_type_cast
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable, :type_cast => true
    end
    
    search = search_class.new
    
    # test number column
    search.age = '12'
    assert_equal 12, search.age
    
    # test text column
    search.name = ' thing '
    assert_equal ' thing ', search.name
    
    # test boolean column
    search.funny = true
    assert_equal true, search.funny
    
    search.funny = false
    assert_equal false, search.funny
    
    search.funny = 1
    assert_equal true, search.funny
    
    search.funny = 0
    assert_equal false, search.funny
  end
  

  def test_empty_search
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
    end
    
    assert_equivalent_request search_class,
                              nil,
                              nil
  end
  

  def test_eq_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :years, :column => :age, :operator => :eq
    end
    

    # nil equality must behaves like ActiveRecord::Base
    assert_equivalent_request search_class,
                              {:conditions => {:age => nil}},
                              {:years => nil}
                              
    # value equality must behaves like ActiveRecord::Base
    assert_equivalent_request search_class,
                              {:conditions => {:age => 50}},
                              {:years => 50}
    
    # array equality must behaves like ActiveRecord::Base
    assert_equivalent_request search_class,
                              {:conditions => {:age => [11,23,54,92,42,24,25,26]}},
                              {:years => [11,23,54,92,42,24,25,26]}
    
    # range equality must behaves like ActiveRecord::Base
    assert_equivalent_request search_class,
                              {:conditions => {:age => 0..20}},
                              {:years => 0..20}
  end


  def test_neq_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :not_funny, :column => :funny, :operator => :neq, :type_cast => true
    end
    

    # nil negation -> don't search (allow null values)
    assert_equivalent_request search_class,
                              {:conditions => "funny IS NOT NULL"},
                              {:not_funny => nil}
                              
    # valued negation
    assert_equivalent_request search_class,
                              {:conditions => ["funny = ? OR funny IS NULL", false]},
                              {:not_funny => true}
    assert_equivalent_request search_class,
                              {:conditions => ["funny = ? OR funny IS NULL", true]},
                              {:not_funny => false}
  end
  
  
  def test_lt_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :limit_age, :column => :age, :operator => :lt
    end
    

    # nil upper bound -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:limit_age => nil}
                              
    # valued upper bound
    assert_equivalent_request search_class,
                              {:conditions => "age < 50"},
                              {:limit_age => 50}
  end


  def test_lte_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :limit_age, :column => :age, :operator => :lte
    end
    

    # nil upper bound -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:limit_age => nil}
                              
    # valued upper bound
    assert_equivalent_request search_class,
                              {:conditions => "age <= 50"},
                              {:limit_age => 50}
  end


  def test_gt_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :limit_age, :column => :age, :operator => :gt
    end
    

    # nil lower bound -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:limit_age => nil}
                              
    # valued lower bound
    assert_equivalent_request search_class,
                              {:conditions => "age > 50"},
                              {:limit_age => 50}
  end


  def test_gte_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :limit_age, :column => :age, :operator => :gte
    end
    

    # nil upper bound -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:limit_age => nil}
                              
    # valued upper bound
    assert_equivalent_request search_class,
                              {:conditions => "age >= 50"},
                              {:limit_age => 50}
  end


  def test_starts_with_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :name_beginning, :column => :name, :operator => :starts_with, :type_cast => true
    end
    

    # nil beginning string -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:name_beginning => nil}
                              
    # empty beginning string -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:name_beginning => ''}
                              
    # valued beginning string
    assert_equivalent_request search_class,
                              {:conditions => ["name like ?", 'Mary%']},
                              {:name_beginning => 'Mary'}
  end
  

  def test_ends_with_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :name_ending, :column => :name, :operator => :ends_with, :type_cast => true
    end
    

    # nil ending string -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:name_ending => nil}
                              
    # empty ending string -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:name_ending => ''}
                              
    # valued ending string
    assert_equivalent_request search_class,
                              {:conditions => ["name like ?", '%Ann']},
                              {:name_ending => 'Ann'}
  end
  

  def test_contains_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :name_partial, :column => :name, :operator => :contains, :type_cast => true
    end
    

    # nil partial string -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:name_partial => nil}
                              
    # empty partial string -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:name_partial => ''}
                              
    # valued partial string
    assert_equivalent_request search_class,
                              {:conditions => ["name like ?", '%ar%']},
                              {:name_partial => 'ar'}
  end
  
  
  def test_full_text_operator
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :keyword, :column => [:name, :city], :operator => :full_text
    end
    

    # nil full text search -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:keyword => nil}
                              
    # empty full text search -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:keyword => nil}
                              
    # valued full text search
    assert_equivalent_request search_class,
                              {:conditions => ["((searchables.`name` like ?) OR (searchables.`city` like ?)) OR ((searchables.`name` like ?) OR (searchables.`city` like ?))", "%Mary%", "%Mary%", "%Paris%", "%Paris%"]},
                              {:keyword => 'Mary Paris'}
  end
  
  
  def test_multi_column_search
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
    end
    
    
    assert_equivalent_request search_class,
                              {:conditions => {:age=>(10..30).to_a, :city=>['Paris', 'London']}},
                              {:age => (10..30).to_a, :city => ['Paris', 'London']}
  end
  
  
  def test_automatic_search_attribute_builders
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    # define some search_accessors
    search_class.class_eval do
      model Searchable
    end
    
    # assert columns names are there
    assert Searchable.columns.map(&:name).all? { |column_name| search_class.search_attributes.include?(column_name.to_sym)}
    
    # assert lower and upper bound search attributes are there
    assert %w(min_age max_age).all? { |column_name| search_class.search_attributes.include?(column_name.to_sym)}
  end
  

  def test_equality_automatic_attributes
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
    end
    

    # nil equality must behaves like ActiveRecord::Base
    conditions = {:age => nil}
    assert_equivalent_request search_class,
                              {:conditions => conditions},
                              conditions
                              
    # value equality must behaves like ActiveRecord::Base
    conditions = {:name => 'Mary'}
    assert_equivalent_request search_class,
                              {:conditions => conditions},
                              conditions
    
    # array equality must behaves like ActiveRecord::Base
    conditions = {:age => [11,23,54,92,42,24,25,26]}
    assert_equivalent_request search_class,
                              {:conditions => conditions},
                              conditions
    
    # range equality must behaves like ActiveRecord::Base
    conditions = {:age => 0..20}
    assert_equivalent_request search_class,
                              {:conditions => conditions},
                              conditions
  end
  

  def test_lower_bound_automatic_attributes
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
    end
    

    # nil lower bound -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:min_age => nil}
                              
    # valued lower bound
    assert_equivalent_request search_class,
                              {:conditions => "age >= 50"},
                              {:min_age => 50}
  end
  

  def test_upper_bound_automatic_attributes
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
    end
    

    # nil upper bound -> don't search (allow null values)
    assert_equivalent_request search_class,
                              nil,
                              {:max_age => nil}
                              
    # valued upper bound
    assert_equivalent_request search_class,
                              {:conditions => "age <= 50"},
                              {:max_age => 50}
  end


  def test_block_defined_search
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :age_limit do |search|
        { :conditions => ["age < ?", search.age_limit] }
      end
    end
    
    assert_equivalent_request search_class,
                              {:conditions => "age < 50"},
                              {:age_limit => 50}
  end
  

  def test_valid_find_options
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :bad_hash do |search|
        { :foo => :bar }  # invalid key
      end
    end
    
    assert_raise ArgumentError do
      search_class.new(:bad_hash => true).find_options
    end
  end


  protected
  
  def assert_equivalent_request(search_class, traditional_find_options, search_options)
    traditional_result_ids = Searchable.find(:all, traditional_find_options).map(&:id).sort
    search_result_ids = Searchable.find(:all, search_class.new(search_options).find_options).map(&:id).sort
    assert !traditional_result_ids.empty?
    assert_equal traditional_result_ids, search_result_ids
  end
end
