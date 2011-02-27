require 'helper'

class TestLogin < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "login and set session id" do
      assert SugarCRM.connection.sugar_session_id.class == String
    end
  end
end