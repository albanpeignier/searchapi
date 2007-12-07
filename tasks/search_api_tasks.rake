RAILS_ENV = "test" unless defined?(RAILS_ENV)
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))

task :searchapi_migrate_test_db do
  ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
  ActiveRecord::Migrator.migrate("vendor/plugins/searchapi/db/migrate/")
end
