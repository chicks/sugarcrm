require 'helper'

class TestGetEntry < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:debug => false })
      @response = SugarCRM.connection.get_entry(
        "Users",
        1,
        {:fields => ["first_name", "last_name"]} 
      )
    end
#    should "return a single entry when sent #get_entry." do
#      assert @response.response. "entry_list"
#    end
    should "return an object when #get_entry" do 
      assert_instance_of SugarCRM::User, @response
    end
  end
end