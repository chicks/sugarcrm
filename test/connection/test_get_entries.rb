require 'helper'

class TestGetEntries < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "return an object when #get_entries" do
      @response = SugarCRM.connection.get_entries(
        "Users",
        [1,"seed_sally_id"],
        {:fields => ["first_name", "last_name"]} 
      )
      assert_instance_of Array, @response
      assert_instance_of SugarCRM::User, @response[0]
    end
  end
end