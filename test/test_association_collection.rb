require 'helper'

class TestAssociationCollection < Test::Unit::TestCase
  context "A SugarCRM::AssociationCollection instance" do
    should "create a new instance when #new" do
      SugarCRM.connect!(URL, USER, PASS)
      u   = SugarCRM::User.find("seed_sarah_id")
      c   = SugarCRM::Contact.find_by_assigned_user_id("seed_sarah_id")
      ac  = SugarCRM::AssociationCollection.new(u,c)
      assert_instance_of SugarCRM::AssociationCollection, ac
    end
  end
end