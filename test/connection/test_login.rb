require 'helper'

class TestLogin < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false})
    end
    should "login and set session id" do
      assert (SugarCRM.connection.session.class == String)
    end
  end
end