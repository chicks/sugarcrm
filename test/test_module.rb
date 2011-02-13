require 'helper'

class TestModule < Test::Unit::TestCase
  context "A SugarCRM::Module instance" do
    should "respond to #fields" do
      assert_respond_to SugarCRM.modules[0], :fields
    end
    
    should "return required fields when #required_fields" do
      assert SugarCRM::User._module.required_fields.include? :user_name
    end
    
    # TODO: Figure out a way to test this.
    #should "return the custom table name when #custom_table_name" do
    #  assert_equal "accounts_cstm", SugarCRM::Account._module.custom_table_name
    #end
  end
  
  context "The SugarCRM class" do
    should "return current user" do
      current_user = SugarCRM.current_user
      assert_instance_of SugarCRM::User, current_user
      assert_equal SugarCRM.sessions.first.config[:username], current_user.user_name
    end
  end
end