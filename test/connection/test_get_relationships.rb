require 'helper'

class TestGetRelationships < Test::Unit::TestCase
  context "A SugarCRM.connection" do
    setup do
      SugarCRM::Connection.new(URL, USER, PASS, {:register_modules => false, :debug => false})
    end
    should "return a list of email_addresses when sent #get_relationship and a user_id" do
      email_address = SugarCRM.connection.get_relationships(
        "Users",1,"email_addresses"
      )
      assert_instance_of SugarCRM::EmailAddress, email_address
    end
  end
end