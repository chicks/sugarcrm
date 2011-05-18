require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'active_support/test_case'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sugarcrm'

CONFIG_PATH = File.join(File.dirname(__FILE__),'config.yaml')

class ActiveSupport::TestCase
  # put your credentials into a YAML file in the test directory
  # the format should be identical to the config_test.yaml found in the same directory
  raise "test/config.yaml file not found. See README for instructions on setting up a testing environment" unless File.exists? CONFIG_PATH
  SugarCRM::Session.from_file(CONFIG_PATH)
end
