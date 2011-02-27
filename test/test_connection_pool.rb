require 'helper'

class TestConnectionPool < ActiveSupport::TestCase
  context "A SugarCRM::ConnectionPool instance" do
    should "have a default pool size of 1 if Rails isn't defined" do
      assert_equal 1, SugarCRM.session.connection_pool.size
    end
  end
end
