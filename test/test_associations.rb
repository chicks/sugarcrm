require 'helper'

class TestAssociations < Test::Unit::TestCase
  context "A SugarCRM::Base instance" do
    should "return an email address when sent #email_addresses" do
      u = SugarCRM::User.find("seed_sarah_id")
      assert_instance_of SugarCRM::AssociationCollection, u.email_addresses
      assert_instance_of SugarCRM::EmailAddress, u.email_addresses.first
      assert_equal "sarah@example.com", u.email_addresses.first.email_address
    end
    
    should "utilize the association cache" do
      u = SugarCRM::User.find(1)
      u.email_addresses
      assert u.association_cached? :email_addresses
    end
    
    should "permit adding a record to an association collection (such as #meetings << Meeting.new)" do
      u = SugarCRM::User.find(1)
      m = SugarCRM::Meeting.new
      m.date_start = DateTime.now
      m.duration_hours = 0.5
      m.name = "Yet Another Stupid Meeting"
      u.meetings << m
      assert u.meetings.include?(m)
      assert_equal [m], u.meetings.added
      assert u.save!
      u = SugarCRM::User.find(1)
      assert u.meetings.include?(m)
      assert u.meetings.delete(m)
      assert u.meetings.save!
      assert !u.meetings.include?(m)
    end
    
    # TODO: Fix created_by_link to only return a single result
    should "return a user when sent #created_by_link" do
      a = SugarCRM::Account.first
      assert_instance_of SugarCRM::User, a.created_by_link.first
    end
  end
end