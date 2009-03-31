# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{searchapi}
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gwendal Rou\303\251"]
  s.date = %q{2009-03-31}
  s.email = ["gr@pierlis.com"]
  s.extra_rdoc_files = ["Manifest.txt"]
  s.files = ["MIT-LICENSE", "Manifest.txt", "README", "Rakefile", "db/migrate/001_create_searchable.rb", "init.rb", "install.rb", "lib/search_api.rb", "lib/search_api/active_record_bridge.rb", "lib/search_api/active_record_integration.rb", "lib/search_api/bridge.rb", "lib/search_api/callbacks.rb", "lib/search_api/errors.rb", "lib/search_api/search.rb", "lib/search_api/sql_fragment.rb", "lib/search_api/text_criterion.rb", "searchapi.gemspec", "tasks/search_api_tasks.rake", "test/active_record_bridge_test.rb", "test/active_record_integration_test.rb", "test/bridge_test.rb", "test/callbacks_test.rb", "test/mock_model.rb", "test/search_test.rb", "uninstall.rb"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{searchapi}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby on Rails plugin which purpose is to let the developper define Search APIs for ActiveRecord models}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.11.0"])
    else
      s.add_dependency(%q<activerecord>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.11.0"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.11.0"])
  end
end
