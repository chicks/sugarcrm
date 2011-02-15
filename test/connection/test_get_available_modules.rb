require 'helper'

class TestGetAvailableModules < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "return an array of modules when #get_modules" do
      assert_instance_of SugarCRM::Module, SugarCRM.connection.get_modules[0]
    end
  end
end