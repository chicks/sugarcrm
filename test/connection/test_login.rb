require 'helper'

class TestLogin < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    should "login and set session id" do
      assert (SugarCRM.connection.session.class == String)
    end
  end
end