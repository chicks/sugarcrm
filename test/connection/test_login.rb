require 'helper'
require "test/unit"
require "pp"

class TestLog < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false})
    end
    should "login and set session id" do
      assert_not_nil SugarCRM.connection.session    
    end
  end
end