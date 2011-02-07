require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sugarcrm'

class Test::Unit::TestCase
  # put your credentials into a YAML file in the test directory
  # the format should be identical to the config_test.yaml found in the same directory
  path = File.join(File.dirname(__FILE__),'config.yaml')
  raise "test/config.yaml file not found. See README for instructions on setting up a testing environment" unless File.exists? path
  SugarCRM::Environment.load_config(path)
end
