# desc "Explaining what the task does"
# task :acts_as_multi_connection do
#   # Task goes here
# end
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
namespace :db do
  task :override => :environment do
    require 'acts_as_multi_connection'
  end
  
  task :migrate => :override do
    configurations = ActiveRecord::Base.configurations
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    sub = configurations[RAILS_ENV.to_s][:sub.to_s]
    if sub
      sub.each do |key, config|
        ActiveRecord::Base.establish_connection(config)
        ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      end
    end
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end
end
