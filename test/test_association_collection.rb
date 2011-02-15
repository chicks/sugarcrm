require 'helper'

class TestAssociationCollection < ActiveSupport::TestCase
  context "A SugarCRM::AssociationCollection instance" do
    should "create a new instance when #new" do
      u   = SugarCRM::User.find("seed_sarah_id")
      ac  = SugarCRM::AssociationCollection.new(u,:email_addresses)
      assert_instance_of SugarCRM::AssociationCollection, ac
    end
  end
end