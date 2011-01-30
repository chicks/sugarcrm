require 'helper'

class TestEnvironment < Test::Unit::TestCase
  context "A SugarCRM::Environment singleton" do
    
    should "delegate missing methods to singleton instance" do
      assert_equal SugarCRM::Environment.instance.config, SugarCRM::Environment.config
    end

    should "load monkey patches" do
      SugarCRM::Environment.monkey_patch_folder = File.join(File.dirname(__FILE__), 'monkey_patch_test')
      assert SugarCRM::Contact.is_monkey_patched?
      assert SugarCRM::Contact.first.is_monkey_patched?
    end
    
    should "load config file" do
      SugarCRM::Environment.load_config File.join(File.dirname(__FILE__), 'config_test.yaml')
      
      config_contents = { 
        :config => {
                      :base_url => 'http://127.0.0.1/sugarcrm',
                      :username => 'admin',
                      :password => 'letmein'
                   }
      }
      
      config_contents[:config].each{|k,v|
        assert_equal v, SugarCRM::Environment.config[k]
      }
    end
  end
  
end
