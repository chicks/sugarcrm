require 'helper'

class TestModule < Test::Unit::TestCase
  context "A SugarCRM::Module instance" do
    
    setup do
      @connection = SugarCRM::Connection.new(URL, USER, PASS)
    end
    
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
end