require 'helper'

class TestGetEntryList < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => true, :debug => false})
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
      users = SugarCRM.connection.get_entry_list(
        "Users",
        "users.deleted = 0"
      ).to_obj
      assert_equal "Administrator", users.first.last_name
    end
    should "return an object when #get_entry_list#to_obj" do
      assert_instance_of Array, @response.to_obj
      assert_instance_of SugarCRM::User, @response.to_obj[0]
    end
  end
end