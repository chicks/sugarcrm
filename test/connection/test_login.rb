require 'helper'

class TestLogin < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "login and set session id" do
      assert (SugarCRM.connection.session_id.class == String)
      assert_equal SugarCRM.connection.session.id, SugarCRM.connection.session_id
    end
  end
end