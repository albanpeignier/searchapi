namespace :searchapi do
  task :migrate_test_db => :environment do
    RAILS_ENV = "test" unless defined?(RAILS_ENV)

    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
    ActiveRecord::Migrator.migrate(File.join(File.dirname(__FILE__), %w{.. db migrate}))
  end
end
