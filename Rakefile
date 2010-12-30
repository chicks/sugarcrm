require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sugarcrm"
    gem.summary = %Q{Ruby based REST client for SugarCRM}
    gem.description = %Q{A less clunky way to interact with SugarCRM via REST.  Instead of SugarCRM.connection.get_entry("Users", "1") you could use SugarCRM::User.find(1).  There is support for collections à la SugarCRM::User.find(1).email_addresses, or SugarCRM::Contact.first.meetings << new_meeting.  ActiveRecord style finders are in place, with limited support for conditions and joins.}
    gem.email = "carl.hicks@gmail.com"
    gem.homepage = "http://github.com/chicks/sugarcrm"
    gem.authors = ["Carl Hicks"]
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_dependency "activesupport", ">= 3.0"    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sugarcrm #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
