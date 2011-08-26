require 'helper'

class TestConnectionPool < ActiveSupport::TestCase
  context "A SugarCRM::ConnectionPool instance" do
    should "have a default pool size of 1 if Rails isn't defined" do
      assert_equal 1, SugarCRM.session.connection_pool.size
    end
    
    should "be able to specify its pool size" do
      config = SugarCRM.session.config
      sess = SugarCRM::Session.new(config[:base_url], config[:username], config[:password], {:connection_pool => {:size => 3}})
      
      begin
        assert_equal 3, sess.connection_pool.size
      ensure
        sess.disconnect!
      end
    end
    
    should "be able to specify its timeout on creation" do
      default_timeout = SugarCRM.session.connection_pool.timeout
      
      config = SugarCRM.session.config
      sess = SugarCRM::Session.new(config[:base_url], config[:username], config[:password], {:connection_pool => {:wait_timeout => default_timeout+1}})
      
      begin
        assert_equal default_timeout+1, sess.connection_pool.timeout
      ensure
        sess.disconnect!
      end
    end
    
    should "be able to specify its timeout after creation" do
      timeout = SugarCRM.session.connection_pool.timeout
      SugarCRM.session.connection_pool.timeout += 1
      
      assert_equal timeout + 1, SugarCRM.session.connection_pool.timeout
    end
  end
end
