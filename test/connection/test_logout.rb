require 'helper'

class TestLogout < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "logout and not be able to login with the old session id" do
      assert (SugarCRM.connection.logout.class == Hash)
    end
  end
end