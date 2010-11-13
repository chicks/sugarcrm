require 'helper'

class TestGetUserTeamID < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false})
    end
    should "get the team ID of the logged in user" do
      assert true, SugarCRM.connection.get_user_team_id
    end
  end
end