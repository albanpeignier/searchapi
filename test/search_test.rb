require 'test/unit'
RAILS_ENV = "test"
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'search_api'
require 'active_record_bridge'
require 'test/mock_model'

class SearchTest < Test::Unit::TestCase
  def test_model
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    # assert model is a public method and that it behaves correctly
    assert_nil search_class.model
    
    # bad usage of ::SearchApi::Search.model
    assert_raise ArgumentError do
      search_class.class_eval do
        model Searchable, Searchable
      end
    end

    # bad model
    assert_raise ArgumentError do
      search_class.class_eval do
        model 1
      end
    end

    # assert ActiveRecord::Base can be used as a model.
    assert_nothing_raised do
      search_class.class_eval do
        model Searchable
      end
    end

    # test reader behavior
    assert_equal Searchable, search_class.model

    # test unicity
    assert_raise RuntimeError do
      search_class.class_eval do
        model Searchable
      end
    end
  end
  
  def test_search_accessor
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # correct usage of search_accessor
    assert_nothing_raised do
      search_class.class_eval do
        search_accessor :a1
        search_accessor 'a2', {}
        search_accessor :a3, :a4
        search_accessor :a5, 'a6', {}
      end
    end
    
    # check bad options
    assert_raise ArgumentError do
      search_class.class_eval do
        search_accessor :a7, :foo => :bar
      end
    end
  end
  
  def test_search_attributes
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)

    # assert search_attributes is empty
    assert_equal [], search_class.search_attributes
    
    # define some search_accessors
    search_class.class_eval do
      search_accessor :a1
      search_accessor 'a2', :a3, 'a4'
    end
    
    # assert search_attributes are symbols
    assert search_class.search_attributes.all? { |x| x.is_a?(Symbol) }
    
    # assert accessors are there
    assert %w(a1 a2 a3 a4).all? { |search_attribute| search_class.search_attributes.include?(search_attribute.to_sym)}
  end
  
  def test_initialize
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # assert no instance can be created without a model
    assert_raise RuntimeError do
      search_class.new
    end
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a, 'b'
    end
    
    # build an instance with an unknown attribute
    assert_raise NoMethodError do
      search_class.new(:foo=>22)
    end
    
    # build an instance with an unknown attribute
    assert_raise NoMethodError do
      search_class.new('foo'=>22)
    end
    
    # build an instance without attributes
    assert_nothing_raised do
      search_class.new
    end
    
    # assert all atributes are ignored for an instance built without attributes
    search = search_class.new
    assert search_class.search_attributes.all? { |search_attribute|
      search.ignored?(search_attribute) &&
      search.send("#{search_attribute}_ignored?")
    }
    
    # build an instance with attributes
    assert_nothing_raised do
      search_class.new(:age => 33, :funny => true, :name => 'jesus', :a => [], :b=>{}, :id => nil)
      search_class.new('age' => 33, 'funny' => true, 'name' => 'jesus', 'a' => [], 'b'=>{}, 'id' => nil)
    end
  end
  
  def test_default_values
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a, :default => 1
      search_accessor :b
    end
    
    search = search_class.new

    assert !search.ignored?(:a)
    assert !search.a_ignored?
    assert_equal 1, search.a
    
    assert search.ignored?(:b)
    assert search.b_ignored?
    assert_equal SearchApi::Search.ignored, search.b
  end
  
  def test_accessors
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a
    end
    
    # build an instance without attributes
    search = search_class.new

    # test default instance_methods are defined, and well-behaved
    search_class.search_attributes.each do |attribute|
      search.ignore!(attribute)
      assert_equal true, search.send("#{attribute}?")
      assert search.ignored?(attribute)
      assert search.send("#{attribute}_ignored?")

      search.send("#{attribute}=", nil)
      assert_nil search.send(attribute)
      assert_equal false, search.send("#{attribute}?")
      assert !search.send("#{attribute}_ignored?")
      assert !search.ignored?(attribute)

      search.send("#{attribute}=", false)
      assert_equal false, search.send(attribute)
      assert_equal false, search.send("#{attribute}?")
      assert !search.send("#{attribute}_ignored?")
      assert !search.ignored?(attribute)

      search.send("#{attribute}=", true)
      assert_equal true, search.send(attribute)
      assert_equal true, search.send("#{attribute}?")
      assert !search.send("#{attribute}_ignored?")
      assert !search.ignored?(attribute)

      search.send("#{attribute}=", 'thing')
      assert_equal 'thing', search.send(attribute)
      assert_equal true, search.send("#{attribute}?")
      assert !search.send("#{attribute}_ignored?")
      assert !search.ignored?(attribute)
    end
  end
  
  def test_attributes
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a, 'b'
    end
    
    # build an instance without attributes
    search = search_class.new
    
    # assert attributes keys are symbols
    assert search.attributes.keys.all? { |x| x.is_a?(Symbol) }
    
    # assert attributes keys are search_class.search_attributes
    assert_equal search_class.search_attributes.map(&:to_s).sort, search.attributes.keys.map(&:to_s).sort
    
    # build an instance with attributes
    attributes = { 'age' => 33, :funny => true, 'name' => 'jesus', :a => [], 'b'=>{}, :id => nil }
    search = search_class.new(Marshal.load(Marshal.dump(attributes)))
    
    # assert set attributes values are what is expected
    attributes.each do |key, value|
      assert_equal value, search.attributes[key.to_sym]
    end
  end
  
  def test_attributes=
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor 'a', :b
    end
    
    # build an instance without attributes
    search = search_class.new
    
    # assert attributes can be set
    attributes = { :age => 33, 'funny' => true, :name => 'jesus', 'a' => [], :b => {}, 'id' => nil }
    assert_nothing_raised do
      search.attributes = Marshal.load(Marshal.dump(attributes))
    end
    
    # assert set attributes values are what is expected
    attributes.each do |key, value|
      assert_equal value, search.attributes[key.to_sym]
    end
    
    # assert partial attributes can be set
    search.attributes = nil
    attributes.each do |key, value|
      assert_equal value, search.attributes[key.to_sym]
    end

    search.attributes = {}
    attributes.each do |key, value|
      assert_equal value, search.attributes[key.to_sym]
    end

    search.attributes = { :a => 'thing', 'b' => 'other' }
    attributes.update('a' => 'thing', :b => 'other').each do |key, value|
      assert_equal value, search.attributes[key.to_sym]
    end
  end
  
  def test_attributes_and_setters_equivalence
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a
    end
    
    # build an instance
    search = search_class.new
    
    # assert calling a setter alters attributes
    search.a = 'thing'
    assert_equal 'thing', search.attributes[:a]
    
    # assert calling attributes= calls setters
    assert_nothing_raised do
      search.attributes = { :a => 12 }
    end
    def search.a=(value)
      raise
    end
    assert_raise RuntimeError do
      search.attributes = { :a => 12 }
    end
  end
  
  def test_initialize_and_setters_equivalence
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a
    end
    
    assert_nothing_raised do
      search_class.new(:a => 12)
    end
    search_class.class_eval do
      define_method(:a=) do
        raise
      end
    end
    assert_raise RuntimeError do
      search_class.new(:a => 12)
    end
  end
  
  def test_store_as_option
    # create a search class
    search_class = Class.new(::SearchApi::Search::Base)
    
    # define some search_accessors
    search_class.class_eval do
      model Searchable
      search_accessor :a, :store_as => proc { |value| value+1 }
    end
    
    search = search_class.new
    
    search.a = 1
    assert_equal 2, search.a
  end
  
end
