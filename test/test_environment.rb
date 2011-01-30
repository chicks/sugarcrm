require 'helper'

class TestEnvironment < Test::Unit::TestCase
  context "A SugarCRM::Environment singleton" do
    
    should "initialize properly" do
      assert SugarCRM::Environment.instance.config == {}
    end
    
    should "delegate missing methods to singleton instance" do
      assert_equal SugarCRM::Environment.instance.config, SugarCRM::Environment.config
    end

    should "load monkey patches" do
      SugarCRM::Environment.monkey_patch_folder = File.join(File.dirname(__FILE__), 'monkey_patch_test')
      assert SugarCRM::Contact.is_monkey_patched?
      assert SugarCRM::Contact.first.is_monkey_patched?
    end
  end
  
end
