require 'helper'
require "test/unit"
require "pp"

class TestSugarcrm < Test::Unit::TestCase
  context "A SugarCRM::Connection instance" do
    
    setup do
      @connection = SugarCRM::Connection.new(URL, USER, PASS, false)
    end
    
    should "login and set session id" do
      assert_not_nil @connection.session    
    end
    
    should "retrieve the list of available modules" do
      assert_instance_of Array, @connection.modules
    end
    
    should "create sub-classes by module name" do
      assert SugarCRM.const_defined? "User"
    end
    
    should "return a single entry when sent #get_entry." do
      response = @connection.get_entry(
        "Users",
        1,
        {:fields => ["first_name", "last_name"]} 
      )
      assert response.response.key? "entry_list"
    end

    should "return a list of entries when sent #get_entries." do
      response = @connection.get_entries(
        "Users",
        [1],
        {:fields => ["first_name", "last_name"]} 
      )
      assert response.key? "entry_list"
    end
    
    should "return a list of entries when sent #get_entry_list and no fields." do
      response = @connection.get_entry_list("Users",1)
      assert_equal response["entry_list"][0]["name_value_list"]["title"]["value"], "Administrator"
    end

    should "return a list of entries when sent #get_entry_list." do
      response = @connection.get_entry_list(
        "Users",
        "users.user_name = \'#{USER}\'",
        {
          :fields => ["first_name", "last_name"],
          :link_fields => [
            {
              "name"  => "accounts",
              "value" => ["id", "name"]
            }
          ]          
        } 
      )
      assert response.key? "entry_list"
    end
    
  end
end