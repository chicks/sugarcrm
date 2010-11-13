require 'helper'
require "test/unit"
require "pp"

class TestGetEntryList < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => true, :debug => true})
      @response = SugarCRM.connection.get_entry_list(
        "Users",
        "users.deleted = 0",
        {:fields => ["first_name", "last_name"]} 
      )
    end
    should "return a list of entries when sent #get_entry_list." do
      assert @response.response.key? "entry_list"
    end
    should "return a list of entries when sent #get_entry_list and no fields." do
      @response = SugarCRM.connection.get_entry_list(
        "Users",
        "users.deleted = 0"
      )
      assert_equal @response["entry_list"][0]["name_value_list"]["title"]["value"], "Administrator"
    end
    should "return an object when #get_entry_list#to_obj" do
      assert_instance_of Array, @response.to_obj
      assert_instance_of SugarCRM::User, @response.to_obj[0]
    end
  end
end