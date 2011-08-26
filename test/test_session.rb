require 'helper'

CONFIG_TEST_PATH = File.join(File.dirname(__FILE__), 'config_test.yaml')

# contents of config_test.yaml
CONFIG_CONTENTS = { 
  :config => {
    :base_url => 'http://127.0.0.1/sugarcrm',
    :username => 'admin',
    :password => 'letmein'
  }
}
CONFIG_CONTENTS.freeze

class TestSession < ActiveSupport::TestCase
  context "The SugarCRM::Session class" do
    should "raise SugarCRM::MissingCredentials if at least one of url/username/password is missing" do
      assert_raise(SugarCRM::MissingCredentials){ SugarCRM.connect('http://127.0.0.1/sugarcrm', nil, nil) }
    end
    
    should "assign namespaces in a way that prevents collisions" do
      begin
        # Namespae0 already assigned (linked to the current connection)
        One = SugarCRM::Session.from_file(CONFIG_PATH)
        Two = SugarCRM::Session.from_file(CONFIG_PATH)
        One.disconnect!
        Three = SugarCRM::Session.from_file(CONFIG_PATH)
        assert_not_equal Two, Three # namespaces must be different
      ensure
        Two.disconnect!
        Three.disconnect!
      end
    end
        
    should "parse config parameters from a file" do
      assert_equal CONFIG_CONTENTS, SugarCRM::Session.parse_config_file(CONFIG_TEST_PATH)
    end
    
    should "create a session from a config file" do
      assert_difference('SugarCRM.namespaces.size') do
        SugarCRM::Session.from_file(CONFIG_PATH)
      end
      
      SugarCRM.const_get(SugarCRM.namespaces.last).disconnect
    end
  end

  context "A SugarCRM::Session instance" do
    should "load monkey patch extensions" do
      SugarCRM.extensions_folder = File.join(File.dirname(__FILE__), 'extensions_test')
      assert SugarCRM::Contact.is_extended?
      assert SugarCRM::Contact.is_extended?
    end
    
    should "implement reload!" do
      assert_nothing_raised do
        SugarCRM.reload!
      end
    end
    
    should "load config file" do
      SugarCRM.load_config CONFIG_TEST_PATH, :reconnect => false
      CONFIG_CONTENTS[:config].each{|k,v| assert_equal v, SugarCRM.config[k]}
      SugarCRM.load_config CONFIG_PATH
    end
    
    should "be able to disconnect, and log in to Sugar automatically if credentials are present in config file" do
      assert_nothing_raised{ SugarCRM.current_user }
      assert SugarCRM.sessions.size == 1
    
      SugarCRM.disconnect!
      assert SugarCRM.sessions.size == 0
      
      assert_raise(SugarCRM::NoActiveSession){ SugarCRM.current_user }
      
      SugarCRM::Session.from_file(CONFIG_PATH)
      
      assert_nothing_raised{ SugarCRM.current_user }
      assert SugarCRM.sessions.size == 1
    end
    
    should "update the login credentials on connection" do
      config = YAML.load_file(CONFIG_PATH) # was loaded in helper.rb
      ["base_url", "username", "password"].each{|k|
        assert_equal config["config"][k], SugarCRM.config[k.to_sym]
      }
    end
    
    should "return the server version" do
      assert_equal String, SugarCRM.sugar_version.class
    end
  end
  
  context "The SugarCRM module" do
    should "show the only the namespaces currently in use with SugarCRM.namespaces" do
      assert_equal 1, SugarCRM.namespaces.size
      
      begin
        assert_difference('SugarCRM.namespaces.size') do
          OneA = SugarCRM::Session.from_file(CONFIG_PATH)
        end
      ensure
        assert_difference('SugarCRM.namespaces.size', -1) do
          OneA.disconnect!
        end
      end
    end
    
    should "add a used namespace on each new connection" do
      begin
        assert_difference('SugarCRM.used_namespaces.size') do
          OneB = SugarCRM::Session.from_file(CONFIG_PATH)
        end
      ensure
        # connection (and namespace) is reused => no used namespace should be added
        assert_no_difference('SugarCRM.used_namespaces.size') do
          OneB.reconnect!
        end
      end
      
      assert_no_difference('SugarCRM.used_namespaces.size') do
        OneB.disconnect!
      end
    end
    
    should "not allow access to methods on SugarCRM if there are multiple active connections" do
      begin
        OneC = SugarCRM::Session.from_file(CONFIG_PATH)
        
        assert_raise(SugarCRM::MultipleSessions){ SugarCRM.current_user }
      ensure
        OneC.disconnect!
      end
    end
  end
end
