require 'helper'
require "test/unit"
require "pp"

class TestGetEntry < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false})
      @response = SugarCRM.connection.get_entry(
        "Users",
        1,
        {:fields => ["first_name", "last_name"]} 
      )
    end
    should "return a single entry when sent #get_entry." do
      assert @response.response.key? "entry_list"
    end
    should "return an object when #get_entry#to_obj" do 
      assert_instance_of SugarCRM::User, @response.to_obj
    end
  end
end