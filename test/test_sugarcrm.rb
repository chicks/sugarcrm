require 'helper'
require "test/unit"
require "pp"

class TestSugarcrm < Test::Unit::TestCase
  context "A SugarCRM::Base instance" do
  
    should "return the module name" do
      assert_equal "Users", SugarCRM::User._module.name
    end
    
    should "respond to self.connection" do
      assert_respond_to SugarCRM::User, :connection
      assert_instance_of SugarCRM::Connection, SugarCRM::User.connection
    end

    should "respond to self.connection.logged_in?" do
      assert SugarCRM::User.connection.logged_in?
    end
  
    should "return an instance of itself when #new" do
      assert_instance_of SugarCRM::User, SugarCRM::User.new
    end
    
    should "define instance level attributes when #new" do
      u = SugarCRM::User.new
      assert SugarCRM::User.attribute_methods_generated
    end

    should "respond to attributes derived from #_module.fields" do
      u = SugarCRM::User.new
      u.last_name = "Test"
      assert_equal "Test", u.last_name
    end
    
    should "return an an instance of itself when sent #find(id)" do
      assert_instance_of SugarCRM::User, SugarCRM::User.find(1)
    end
    
    should "receive a response containing all fields when sent #get_entry" do
      u = SugarCRM::User.find(1)
      assert_equal u.user_name, "admin"
    end
  end
  
end
