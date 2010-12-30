require 'helper'

class TestAssociations < Test::Unit::TestCase
  context "A SugarCRM::Base instance" do
    should "return an email address when sent #email_addresses" do
      u = SugarCRM::User.find("seed_sarah_id")
      assert_equal "sarah@example.com", u.email_addresses.first.email_address
    end
    
    should "utilize the association cache" do
      u = SugarCRM::User.find(1)
      u.email_addresses
      assert u.association_cached? :email_addresses
    end
    
    should "permit adding a record to an association collection (such as #email_addresses << EmailAddress.new)" do
      u = SugarCRM::User.find(1)
      e = SugarCRM::EmailAddress.new
      e.email_address = "admin@gmail.com"
      e.email_address_caps = "ADMIN@GMAIL.COM"
      u.email_addresses << e
      assert u.email_addresses.include?(e)
      assert_equal [e], u.email_addresses.added
      assert u.save!
      u = SugarCRM::User.find(1)
      assert u.email_addresses.include?(e)
      assert u.email_addresses.delete(e)
    end
  end
end