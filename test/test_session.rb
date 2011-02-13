require 'helper'

class TestSession < Test::Unit::TestCase
  context "A SugarCRM::Session instance" do
    setup do
      @current_session = SugarCRM.sessions.first
    end

    should "load monkey patch extensions" do
      @current_session.extensions_folder = File.join(File.dirname(__FILE__), 'extensions_test')
      assert SugarCRM::Contact.is_extended?
      assert SugarCRM::Contact.is_extended?
    end
    
#     should "load config file" do
#       SugarCRM::Environment.load_config File.join(File.dirname(__FILE__), 'config_test.yaml')
#       
#       config_contents = { 
#         :config => {
#                       :base_url => 'http://127.0.0.1/sugarcrm',
#                       :username => 'admin',
#                       :password => 'letmein'
#                    }
#       }
#       
#       config_contents[:config].each{|k,v|
#         assert_equal v, SugarCRM::Environment.config[k]
#       }
#     end
#     
#     should "log in to Sugar automatically if credentials are present in config file" do
#       SugarCRM::Environment.load_config File.join(File.dirname(__FILE__), 'config_test.yaml')
#       assert SugarCRM.connection.logged_in?
#     end
    
    should "update the login credentials on connection" do
      config = YAML.load_file(File.join(File.dirname(__FILE__), 'config.yaml')) # was loaded in helper.rb
      ["base_url", "username", "password"].each{|k|
        assert_equal config["config"][k], @current_session.config[k.to_sym]
      }
    end
    
    should "return the server version" do
      assert_equal String, @current_session.sugar_version.class
    end
  end
  
end
