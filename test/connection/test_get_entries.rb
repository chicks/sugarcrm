require 'helper'

class TestGetEntries < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => true, :debug => false})
      @response = SugarCRM.connection.get_entries(
        "Users",
        [1,"seed_sally_id"],
        {:fields => ["first_name", "last_name"]} 
      )
    end
#    should "return a list of entries when sent #get_entries." do
#      assert @response.response.key? "entry_list"
#    end
    should "return an object when #get_entries" do
      assert_instance_of Array, @response
      assert_instance_of SugarCRM::User, @response[0]
    end
  end
end