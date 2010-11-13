require 'helper'

class TestModuleFields < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:debug => false, :register_modules => false})
    end
    should "return a hash of module fields when #get_module_fields" do
      fields = SugarCRM.connection.get_module_fields("Users")
      assert_instance_of Hash, fields
      assert "address_city", fields.keys[0]
    end
  end
end