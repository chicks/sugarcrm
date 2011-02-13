require 'helper'

class TestConnection < Test::Unit::TestCase
  context "A SugarCRM::Connection instance" do
    should "retrieve the list of available modules" do
      assert_instance_of Array, SugarCRM.modules
      assert_instance_of SugarCRM::Module, SugarCRM.modules[0]
    end
    should "create sub-classes by module name" do
      assert SugarCRM.sessions.first.namespace_const.const_defined? "User"
    end
  end
end