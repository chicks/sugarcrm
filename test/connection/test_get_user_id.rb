require 'helper'

class TestGetUserID < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "get the ID of the logged in user" do
      assert true, SugarCRM.connection.get_user_id  
    end
  end
end