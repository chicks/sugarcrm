require 'helper'

class TestModule < ActiveSupport::TestCase
  context "A SugarCRM::Module instance" do
    should "respond to #fields" do
      assert_respond_to SugarCRM.modules[0], :fields
    end
    
    should "return required fields when #required_fields" do
      assert SugarCRM::Account._module.required_fields.include? :name
    end
    
    # TODO: Figure out a way to test this.
    #should "return the custom table name when #custom_table_name" do
    #  assert_equal "accounts_cstm", SugarCRM::Account._module.custom_table_name
    #end
  end
  
  context "SugarCRM::Module" do
    should "find modules" do
      assert_instance_of SugarCRM::Module, SugarCRM::Module.find("Accounts")
    end
    
    should "(de)register all modules" do
      assert SugarCRM.modules.size > 0
      assert SugarCRM.session.namespace_const.const_defined? 'User'
      
      SugarCRM::Module.deregister_all(SugarCRM.session)
      assert SugarCRM.modules.size == 0
      assert ! (SugarCRM.session.namespace_const.const_defined? 'User')
      
      SugarCRM::Module.register_all(SugarCRM.session)
      assert SugarCRM.modules.size > 0
      assert SugarCRM.session.namespace_const.const_defined? 'User'
    end
  end
  
  context "The SugarCRM class" do
    should "return current user" do
      current_user = SugarCRM.current_user
      assert_instance_of SugarCRM::User, current_user
      assert_equal SugarCRM.config[:username], current_user.user_name
    end
    
    should "implement reload!" do
      assert_nothing_raised do
        SugarCRM.reload!
      end
    end
  end
end