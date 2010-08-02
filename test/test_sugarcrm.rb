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
    
  end
  
  context "A SugarCRM::Module instance" do
  
    should "return the module name" do
      assert_equal "Users", SugarCRM::User.module_name
    end
    
    should "respond to self.connection" do
      assert_respond_to SugarCRM::User, :connection
      assert_instance_of SugarCRM::Connection, SugarCRM::User.connection
    end
    
    should "respond to self.register_module_fields" do
      assert_respond_to SugarCRM::User, :register_module_fields
      SugarCRM::User.register_module_fields
      assert SugarCRM::User.module_fields.length > 0
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

    should "respond to attributes derived from module_fields" do
      u = SugarCRM::User.new
      u.last_name = "Test"
      assert_equal "Test", u.last_name
    end
    
    should "return an an instance of itself when sent #find(id)" do
      u = SugarCRM::User.find(1)
      assert_instance_of SugarCRM::User, u
    end
  end
  
end
