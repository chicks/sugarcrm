require 'helper'

class TestSetRelationship < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    should "add and remove a relationship when #set_relationship" do
      SugarCRM.connect(URL, USER, PASS, {:debug => false})    
      meeting  = SugarCRM::Meeting.new
      meeting.date_start = DateTime.now
      meeting.duration_hours = 0.5
      meeting.name = "Stupid Meeting"
      assert meeting.save!
      response = SugarCRM.connection.set_relationship("Users","1","meetings", [meeting.id])
      assert response["created"] == 1
      response = SugarCRM.connection.set_relationship("Users","1","meetings", [meeting.id], {:delete => 1})
      assert response["deleted"] == 1
      assert meeting.delete
    end
  end
end