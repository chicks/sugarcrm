require 'helper'

# Replace these with your test instance
URL   = "http://valet/sugarcrm"
USER  = "admin"
PASS  = 'letmein' 

class TestSugarcrm < Test::Unit::TestCase
  context "A SugarCRM::Base instance" do
    setup do
      @sugarcrm = SugarCRM::Base.new(URL, USER, PASS, {:debug => true})
    end
    
    should "return a single entry in JSON format when option :to_obj => false" do
      @test = SugarCRM::Base.new(URL, USER, PASS, {:debug => true, :to_obj => false})
      response = @test.get_entry(
        "Users",
        1,
        {:fields => ["first_name", "last_name"]} 
      )
      assert_kind_of Hash, response
    end
    
    should "return a single entry when sent #get_entry." do
      response = @sugarcrm.get_entry(
        "Users",
        1,
        {:fields => ["first_name", "last_name"]} 
      )
      assert_respond_to 'response', :entry_list
    end
    
    should "return a list of entries when sent #get_entries." do
      response = @sugarcrm.get_entries(
        "Users",
        [1],
        {:fields => ["first_name", "last_name"]} 
      )
      assert_respond_to 'response', :entry_list
    end
    
    should "return a list of entries when sent #get_entry_list." do
      response = @sugarcrm.get_entry_list(
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
      assert_respond_to 'response', :entry_list
    end
    
  end
end
