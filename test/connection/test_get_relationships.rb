require 'helper'

class TestGetRelationships < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "return a list of email_addresses when sent #get_relationship and a user_id" do
      email_addresses = SugarCRM.connection.get_relationships(
        "Users",1,"email_addresses"
      )
      assert_instance_of SugarCRM::EmailAddress, email_addresses.first
    end
  end
end