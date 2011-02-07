require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sugarcrm'

class Test::Unit::TestCase
  # put your credentials into a YAML file in the test directory
  # the format should be identical to the config_test.yaml found in the same directory
  SugarCRM::Environment.load_config(File.join(File.dirname(__FILE__),'config.yaml'))
end
