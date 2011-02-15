require 'helper'

class TestGetEntry < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    setup do
      @response = SugarCRM.connection.get_entry(
        "Users",
        1,
        {:fields => ["first_name", "last_name", "deleted", "date_modified"]} 
      )
    end
    should "return an object when #get_entry" do 
      assert_instance_of SugarCRM::User, @response
    end
    should "typecast boolean fields properly" do
      assert_instance_of FalseClass, @response.deleted
    end
    should "typecast date_time fields properly" do
      assert_instance_of DateTime, @response.date_modified
    end
  end
end