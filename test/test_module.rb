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
      assert SugarCRM::User._module.required_fields.include? "user_name"
    end
  end
end