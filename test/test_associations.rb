require 'helper'

class TestAssociations < ActiveSupport::TestCase
  context "A SugarCRM::Associations class" do
    should "Return an array of Association objects when self#register(SugarCRM::User.new)" do
      associations = SugarCRM::Associations.register(SugarCRM::User.new)
      assert associations.include? "email_addresses"
      assert associations.proxy_methods.include? "email_addresses"
    end
  end
  
  context "A SugarCRM::Association class" do
    should "compute relationship cardinality correctly" do
      c = SugarCRM::Case.first
      link_fields_hash = c.associations.classify{|i| i.link_field}
      # TODO: test one_to_one cardinality by creating custom module with custom relationship
      # (no "official" one-to-one relationship exists in Sugar out of the box)
      assert_equal :one_to_many, link_fields_hash['calls'].first.cardinality
      assert_equal :many_to_one, link_fields_hash['accounts'].first.cardinality
      assert_equal :many_to_many, link_fields_hash['contacts'].first.cardinality
    end
    should "respond to #pretty_print" do
      a = SugarCRM::Case.first.associations.first
      assert_respond_to a, :pretty_print
    end
  end
  
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
    
    should "create relationships with associate!" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      nb_contacts = a.contacts.size
      a.associate!(c)
      assert_equal nb_contacts + 1, a.contacts.size # test association_cache is updated
      
      assert_equal nb_contacts + 1, SugarCRM::Account.first.contacts.size # test relationship is created in Sugar
      
      assert c.delete
    end
    
    should "destroy relationships with disassociate!" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      a.associate!(c)
      nb_contacts = a.contacts.size
      a.disassociate!(c)
      assert_equal nb_contacts - 1, a.contacts.size # test association_cache is updated
      
      assert_equal nb_contacts - 1, SugarCRM::Account.first.contacts.size # test relationship is destroyed in Sugar
      
      assert c.delete
    end
    
    should "not destroy a relationship if associate! is called with {:delete => 0}" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      a.associate!(c)
      nb_contacts = a.contacts.size
      a.associate!(c, {:delete => 0})
      assert_equal nb_contacts, a.contacts.size
      
      assert c.delete
    end
    
    should "update association cache on associate! only if association changes" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      nb_contacts = a.contacts.size
      a.associate!(c)
      assert_equal nb_contacts + 1, a.contacts.size
      a.associate!(c)
      assert_equal nb_contacts + 1, a.contacts.size # should not change: already associated
      
      assert c.delete
    end
    
    should "update association cache on << only if association changes" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      nb_contacts = a.contacts.size
      a.contacts  << c
      assert_equal nb_contacts + 1, a.contacts.size
      a.contacts  << c
      assert_equal nb_contacts + 1, a.contacts.size # should not change: already associated
      
      assert c.delete
    end
    
    should "update association cache for both sides of the relationship when calling associate!" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      nb_contacts = a.contacts.size
      nb_accounts = c.accounts.size
      a.associate!(c)
      assert_equal nb_contacts + 1, a.contacts.size
      assert_equal nb_accounts + 1, c.accounts.size
      
      assert c.delete
    end
    
    should "update association cache for both sides of the relationship when calling <<" do
      a = SugarCRM::Account.first
      c = SugarCRM::Contact.create(:last_name => 'Doe')
      
      nb_contacts = a.contacts.size
      nb_accounts = c.accounts.size
      a.contacts  << c
      assert_equal nb_contacts + 1, a.contacts.size
      assert_equal nb_accounts + 1, c.accounts.size
      
      assert c.delete
    end
  end
end