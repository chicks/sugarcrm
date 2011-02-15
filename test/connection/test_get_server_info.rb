require 'helper'

class TestGetServerInfo < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "get server info" do
      assert_instance_of String, SugarCRM.connection.get_server_info["version"]
    end
  end
end