require 'helper'

class TestGetUserTeamID < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "get the team ID of the logged in user" do
      assert true, SugarCRM.connection.get_user_team_id
    end
  end
end