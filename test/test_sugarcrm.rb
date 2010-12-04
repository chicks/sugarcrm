require 'helper'

class TestSugarCRM < Test::Unit::TestCase
  context "A SugarCRM::Base instance" do
    
    should "establish a connection when SugarCRM#connect!" do
      SugarCRM.connect!(URL, USER, PASS)
      assert SugarCRM.connection.connected?
    end
    
    should "establish a connection when Base#establish_connection" do
      SugarCRM::Base.establish_connection(URL, USER, PASS)
      assert SugarCRM.connection.connected?
    end
  
    should "return the module name" do
      assert_equal "Users", SugarCRM::User._module.name
    end
    
    should "responsd to self#methods" do
      assert_instance_of Array, SugarCRM::User.new.methods
    end
    
    should "respond to self.connection" do
      assert_respond_to SugarCRM::User, :connection
      assert_instance_of SugarCRM::Connection, SugarCRM::User.connection
    end

    should "respond to self.connection.logged_in?" do
      assert_respond_to SugarCRM::User.connection, :logged_in?
    end
    
    should "respond to self.current_user" do
      assert_instance_of SugarCRM::User, SugarCRM.current_user
    end
  
    should "respond to self.attributes_from_modules_fields" do
      assert_instance_of ActiveSupport::HashWithIndifferentAccess, SugarCRM::User.attributes_from_module_fields
    end
  
    should "return an instance of itself when #new" do
      assert_instance_of SugarCRM::User, SugarCRM::User.new
    end
    
    should "define instance level attributes when #new" do
      u = SugarCRM::User.new
      assert SugarCRM::User.attribute_methods_generated
    end

    should "not save a record that is missing required attributes" do
      u = SugarCRM::User.new
      u.last_name = "Test"
      assert !u.save
      assert_raise SugarCRM::MissingRequiredAttributes do
        u.save!
      end
    end

    should "create, modify, and save a new record" do
      u = SugarCRM::User.new
      u.email1 = "abc@abc.com"
      u.last_name = "Test"
      u.system_generated_password = 0
      u.user_name = "test_user"
      u.status = {"Active"=>{"name"=>"Active", "value"=>"Active"}}
      assert_equal "Test", u.modified_attributes[:last_name][:new]
      assert u.save!
    end
    
    should "return an an instance of itself when sent #find(id)" do
      assert_instance_of SugarCRM::User, SugarCRM::User.find(1)
    end
    
    should "receive a response containing all fields when sent #get_entry" do
      u = SugarCRM::User.find(1)
      assert_equal u.user_name, "admin"
    end
    
    should "return an email address when sent #email_addresses" do
      u = SugarCRM::User.find("seed_sarah_id")
      assert_equal "sarah@example.com", u.email_addresses.first.email_address
    end

    should "return an array of records when sent #find([id1, id2, id3])" do
      users = SugarCRM::User.find(["seed_sarah_id", 1])
      assert_equal "Administrator", users.last.title
    end
    
    should "return an instance of User when sent User#find_by_username" do
      u = SugarCRM::User.find_by_user_name("sarah")
      assert_equal "sarah@example.com", u.email_addresses.first.email_address
    end

  end
  
end
