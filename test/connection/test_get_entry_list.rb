require 'helper'

class TestGetEntryList < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "return a list of entries when sent #get_entry_list" do
      users = SugarCRM.connection.get_entry_list(
        "Users",
        "users.deleted = 0"
      )
      assert_kind_of Array, users
      assert_equal SugarCRM.config[:username], users.first.user_name
    end
    should "return an object when #get_entry_list" do
      @response = SugarCRM.connection.get_entry_list(
        "Users",
        "users.deleted = 0",
        {:fields => ["first_name", "last_name"]} 
      )
      assert_instance_of Array, @response
      assert_instance_of SugarCRM::User, @response[0]
    end
  end
end
