# -*- coding: utf-8 -*-
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the searchapi plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the search_api plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SearchApi'
  rdoc.options << '--line-numbers' << '--inline-source' << '-c utf-8'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

%w[rubygems hoe].each { |f| require f }
# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('searchapi', '0.1') do |p|
  p.developer("Gwendal Roué", "gr@pierlis.com")
  p.summary = "Ruby on Rails plugin which purpose is to let the developper define Search APIs for ActiveRecord models"
  p.rubyforge_name       = p.name # TODO this is default value
  p.extra_deps         = [['activerecord']]

  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

desc 'Recreate Manifest.txt to include ALL files'
task :manifest do
  `rake check_manifest | patch -p0 > Manifest.txt`
end

desc "Generate a #{$hoe.name}.gemspec file"
task :gemspec do
  File.open("#{$hoe.name}.gemspec", "w") do |file|
    file.puts $hoe.spec.to_ruby
  end
end
