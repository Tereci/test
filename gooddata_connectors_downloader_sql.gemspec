# -*- encoding: utf-8 -*-
# stub: gooddata_connectors_downloader_sql 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gooddata_connectors_downloader_sql".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adrian Toman".freeze]
  s.date = "2019-08-05"
  s.description = "The gem wraping the SQL connector implementation for Gooddata Connectors infrastructure".freeze
  s.email = ["adrian.toman@gooddata.com".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".rubocop.yml".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "gooddata_connectors_downloader_sql.gemspec".freeze, "lib/gooddata_connectors_downloader_sql.rb".freeze, "lib/gooddata_connectors_downloader_sql/backends/backends.rb".freeze, "lib/gooddata_connectors_downloader_sql/backends/base_backend.rb".freeze, "lib/gooddata_connectors_downloader_sql/backends/drivers/mysql-connector-java-5.1.35-bin.jar".freeze, "lib/gooddata_connectors_downloader_sql/backends/drivers/postgresql-9.4.1212.jre6.jar".freeze, "lib/gooddata_connectors_downloader_sql/backends/drivers/sqljdbc41.jar".freeze, "lib/gooddata_connectors_downloader_sql/backends/ms_sql.rb".freeze, "lib/gooddata_connectors_downloader_sql/backends/ms_sql_v2.rb".freeze, "lib/gooddata_connectors_downloader_sql/backends/my_sql.rb".freeze, "lib/gooddata_connectors_downloader_sql/backends/psql.rb".freeze, "lib/gooddata_connectors_downloader_sql/extensions/extensions.rb".freeze, "lib/gooddata_connectors_downloader_sql/extensions/object.rb".freeze, "lib/gooddata_connectors_downloader_sql/schema/validation_schema.json".freeze, "lib/gooddata_connectors_downloader_sql/sql.rb".freeze, "lib/gooddata_connectors_downloader_sql/version.rb".freeze, "spec/data/configurations/configuration_1.json".freeze, "spec/data/configurations/configuration_2.json".freeze, "spec/data/configurations/configuration_3.json".freeze, "spec/data/configurations/configuration_4.json".freeze, "spec/data/configurations/default_configuration.json".freeze, "spec/data/files/feature/contractors.csv".freeze, "spec/data/files/feature/event.csv".freeze, "spec/data/files/feature/event2.csv".freeze, "spec/data/files/feature/expected_metadata_contractors.json".freeze, "spec/data/files/feature/expected_metadata_event.json".freeze, "spec/data/files/feature/expected_metadata_event2.json".freeze, "spec/data/files/feature/expected_metadata_event3.json".freeze, "spec/data/files/feature/expected_metadata_sales.json".freeze, "spec/data/files/feature/sales.csv".freeze, "spec/environment/default.rb".freeze, "spec/features/prepares_data_for_ads_spec.rb".freeze, "spec/helpers/connections_helper.rb".freeze, "spec/helpers/s3_helper.rb".freeze, "spec/spec_helper.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/base_backend_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/ms_sql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/ms_sql_v2_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/my_sql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/psql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/sql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/version_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql_spec.rb".freeze]
  s.homepage = "".freeze
  s.licenses = ["BSD".freeze]
  s.rubygems_version = "2.6.6".freeze
  s.summary = "".freeze
  s.test_files = ["spec/data/configurations/configuration_1.json".freeze, "spec/data/configurations/configuration_2.json".freeze, "spec/data/configurations/configuration_3.json".freeze, "spec/data/configurations/configuration_4.json".freeze, "spec/data/configurations/default_configuration.json".freeze, "spec/data/files/feature/contractors.csv".freeze, "spec/data/files/feature/event.csv".freeze, "spec/data/files/feature/event2.csv".freeze, "spec/data/files/feature/expected_metadata_contractors.json".freeze, "spec/data/files/feature/expected_metadata_event.json".freeze, "spec/data/files/feature/expected_metadata_event2.json".freeze, "spec/data/files/feature/expected_metadata_event3.json".freeze, "spec/data/files/feature/expected_metadata_sales.json".freeze, "spec/data/files/feature/sales.csv".freeze, "spec/environment/default.rb".freeze, "spec/features/prepares_data_for_ads_spec.rb".freeze, "spec/helpers/connections_helper.rb".freeze, "spec/helpers/s3_helper.rb".freeze, "spec/spec_helper.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/base_backend_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/ms_sql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/ms_sql_v2_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/my_sql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/backends/psql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/sql_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql/version_spec.rb".freeze, "spec/unit/gooddata_connectors_downloader_sql_spec.rb".freeze]

  s.installed_by_version = "2.6.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 10.4.2", "~> 10.4"])
      s.add_development_dependency(%q<rake-notes>.freeze, [">= 0.2.0", "~> 0.2"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 3.3.0", "~> 3.3"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.41.2"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0.10.0", "~> 0.10"])
      s.add_runtime_dependency(%q<sequel>.freeze, ["= 4.38.0"])
    else
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 10.4.2", "~> 10.4"])
      s.add_dependency(%q<rake-notes>.freeze, [">= 0.2.0", "~> 0.2"])
      s.add_dependency(%q<rspec>.freeze, [">= 3.3.0", "~> 3.3"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.41.2"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0.10.0", "~> 0.10"])
      s.add_dependency(%q<sequel>.freeze, ["= 4.38.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 10.4.2", "~> 10.4"])
    s.add_dependency(%q<rake-notes>.freeze, [">= 0.2.0", "~> 0.2"])
    s.add_dependency(%q<rspec>.freeze, [">= 3.3.0", "~> 3.3"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.41.2"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0.10.0", "~> 0.10"])
    s.add_dependency(%q<sequel>.freeze, ["= 4.38.0"])
  end
end
