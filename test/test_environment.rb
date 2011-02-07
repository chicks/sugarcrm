require 'helper'

class TestEnvironment < Test::Unit::TestCase
  context "A SugarCRM::Environment singleton" do
    
    should "delegate missing methods to singleton instance" do
      assert_equal SugarCRM::Environment.instance.config, SugarCRM::Environment.config
    end

    should "load monkey patch extensions" do
      SugarCRM::Environment.extensions_folder = File.join(File.dirname(__FILE__), 'extensions_test')
      assert SugarCRM::Contact.is_extended?
      assert SugarCRM::Contact.is_extended?
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
    
    should "log in to Sugar automatically if credentials are present in config file" do
      SugarCRM::Environment.load_config File.join(File.dirname(__FILE__), 'config_test.yaml')
      assert SugarCRM.connection.logged_in?
    end
    
    should "update the login credentials on connection" do
      config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml'))
      ["base_url", "username", "password"].each{|k|
        assert_equal config["config"][k], SugarCRM::Environment.config[k.to_sym]
      }
    end
    
    should "return the server version" do
      assert_equal String, SugarCRM::Environment.version.class
    end
  end
  
end
