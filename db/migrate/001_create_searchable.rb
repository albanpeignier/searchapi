require File.expand_path(File.join(File.dirname(__FILE__), '../../test/mock_model'))

class CreateSearchable < ActiveRecord::Migration
  def self.up
    create_table :searchables do |t|
      t.column :age, :integer
      t.column :name, :string
      t.column :city, :string
      t.column :funny, :boolean, :default => true
    end
    
    # fill in plenty of random records
    
    1000.times do
      Searchable.create(
        :age => case age = rand(100)
                  when 0; nil
                  else age
                end,
        :name => (%w(John Mary Bob Andy Sylvia Marc Ann Mary-Ann)+[nil])[rand(9)],
        :city => (%w(Paris London Berlin Madrid Roma Budapest Bruxelles Lisboa)+[nil])[rand(9)],
        :funny => case rand(3)
                    when 0; nil
                    when 1: true
                    when 2: false
                  end)
    end
  end

  def self.down
    drop_table :searchables
  end
end
