require 'helper'

class TestSetRelationships < Test::Unit::TestCase    
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false, :debug => false})    
      
      #retrieve ID of ACLRole and append shove it into the @id array
      @id = [SugarCRM::ACLRole.find_by_name("Marketing Administrator").id]
      assert @id
    end
    
    should "add the role found above to the user who's id is below when sent #set_relationship" do
      response = SugarCRM.connection.set_relationship(
        "Users","seed_will_id","aclroles",@id
      )
      assert_equal("failed0deleted0created1", response.to_s)
    end
    
    should "remove the role that was previously added when sent #set_relationship and delete=1" do
      response = SugarCRM.connection.set_relationship(
        "Users","seed_will_id","aclroles",@id,opts={:delete => 1}
      )
      assert_equal("failed0deleted1created0", response.to_s)
    end
  end
end