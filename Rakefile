require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "sugarcrm"
  gem.summary = %Q{Ruby based REST client for SugarCRM}
  gem.description = %Q{A less clunky way to interact with SugarCRM via REST.  Instead of SugarCRM.connection.get_entry("Users", "1") you could use SugarCRM::User.find(1).  There is support for collections a la SugarCRM::User.find(1).email_addresses, or SugarCRM::Contact.first.meetings << new_meeting.  ActiveRecord style finders are in place, with limited support for conditions and joins.}
  gem.email = "carl.hicks@gmail.com"
  gem.homepage = "http://github.com/chicks/sugarcrm"
  gem.authors = ["Carl Hicks"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sugarcrm #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end