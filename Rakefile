require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sugarcrm"
    gem.summary = %Q{Ruby based REST client for SugarCRM}
    gem.description = %Q{I've implemented all of the basic API calls that SugarCRM supports, and am actively building an abstraction layer
    on top of the basic API methods.  The end result will be to provide ActiveRecord style finders and first class
    objects.  Some of this functionality is included today.}
    gem.email = "carl.hicks@gmail.com"
    gem.homepage = "http://github.com/chicks/sugarcrm"
    gem.authors = ["Carl Hicks"]
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_dependency "json", ">= 0"
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
