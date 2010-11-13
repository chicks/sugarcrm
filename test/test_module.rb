require 'helper'

class TestModule < Test::Unit::TestCase
  context "A SugarCRM::Module instance" do
    
    setup do
      @connection = SugarCRM::Connection.new(URL, USER, PASS)
    end
    
    should "respond to #fields" do
      assert_respond_to SugarCRM.modules[0], :fields
    end
  end
end