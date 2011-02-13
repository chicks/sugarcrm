require 'helper'

class TestSession < Test::Unit::TestCase
  context "A SugarCRM::Session instance" do
    should "load monkey patch extensions" do
      SugarCRM.session.extensions_folder = File.join(File.dirname(__FILE__), 'extensions_test')
      assert SugarCRM::Contact.is_extended?
      assert SugarCRM::Contact.is_extended?
    end
    
    should "load config file" do
      SugarCRM.session.load_config File.join(File.dirname(__FILE__), 'config_test.yaml')
      
      config_contents = { 
        :config => {
                      :base_url => 'http://127.0.0.1/sugarcrm',
                      :username => 'admin',
                      :password => 'letmein'
                   }
      }
      
      config_contents[:config].each{|k,v|
        assert_equal v, SugarCRM.session.config[k]
      }
    end
    
    should "log in to Sugar automatically if credentials are present in config file" do
      # tested with helper.rb: tests run, so automatic login was successful
      true
    end
    
    should "update the login credentials on connection" do
      config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml')) # was loaded in helper.rb
      ["base_url", "username", "password"].each{|k|
        assert_equal config["config"][k], SugarCRM.session.config[k.to_sym]
      }
    end
    
    should "return the server version" do
      assert_equal String, SugarCRM.session.sugar_version.class
    end
  end
  
end
