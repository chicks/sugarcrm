require 'helper'

class TestGetServerInfo < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false})
    end
    should "get server info" do
      assert_instance_of String, SugarCRM.connection.get_server_info["version"]
    end
  end
end