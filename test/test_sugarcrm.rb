require 'helper'

class TestSugarCRM < ActiveSupport::TestCase
  context "A class inheriting SugarCRM::Base" do
    should "ignore 'id' attibute when creating an instance" do
      first_account = SugarCRM::Account.first
      new_account = nil
      assert_difference('SugarCRM::Account.count') do
        new_account = SugarCRM::Account.create(first_account.attributes)
      end
      assert first_account.id != new_account.id
    end
    
    should "implement self.count" do
      nb_accounts = SugarCRM::Account.count
      assert nb_accounts > 0, "There should be some Accounts"
      nb_inc_accounts = nil
      assert_nothing_raised do
        nb_inc_accounts = SugarCRM::Account.count(:conditions => {:name => "LIKE '%Inc'"})
      end
      nb_inc_accounts_size = SugarCRM::Account.all(:conditions => {:name => "LIKE '%Inc'"}).size
      assert nb_inc_accounts > 0
      assert nb_inc_accounts < nb_accounts
      assert_equal nb_inc_accounts_size, nb_inc_accounts
    end
    
    should "raise InvalidAttribute if self.count is called with a custom attribute" do
      assert_raise SugarCRM::InvalidAttribute do
        SugarCRM::Account.count(:conditions => {:custom_attribute_c => "value"})
      end
    end
  end
  
  context "A SugarCRM::Base instance" do
  
    should "return the module name" do
      assert_equal "Users", SugarCRM::User._module.name
    end
    
    should "return the module fields" do
      assert_kind_of Hash, SugarCRM::Account._module.fields
    end
    
    should "respond to self#methods" do
      assert_instance_of Array, SugarCRM::User.new.methods
    end
    
    should "respond to self.connection" do
      assert_respond_to SugarCRM::User, :connection
      assert_instance_of SugarCRM::Connection, SugarCRM::User.connection
    end

    should "respond to self.connection.logged_in?" do
      assert_respond_to SugarCRM::User.connection, :logged_in?
    end
    
    should "respond to self.current_user" do
      assert_instance_of SugarCRM::User, SugarCRM.current_user
    end
  
    should "respond to self.attributes_from_modules_fields" do
      assert_kind_of Hash, SugarCRM::User.attributes_from_module
    end
  
    should "return an instance of itself when #new" do
      assert_instance_of SugarCRM::User, SugarCRM::User.new
    end
    
    should "define instance level attributes when #new" do
      u = SugarCRM::User.new
      assert SugarCRM::User.attribute_methods_generated
    end

    should "not save a record that is missing required attributes" do
      u = SugarCRM::User.new
      u.last_name = "Test"
      assert !u.save
      assert_raise SugarCRM::InvalidRecord do
        u.save!
      end
    end

    should "create, modify, and delete a record" do
      u = SugarCRM::User.new
      assert u.email1?
      u.email1 = "abc@abc.com"
      u.first_name = "Test"
      u.last_name = "User"
      u.system_generated_password = false
      u.user_name = "test_user"
      u.status = "Active"
      assert_equal "Test", u.modified_attributes[:first_name][:new]
      assert u.save!
      assert !u.new?
      m = SugarCRM::User.find_by_first_name_and_last_name("Test", "User")
      assert m.user_name != "admin"
      m.title = "Test User"
      assert m.save!
      assert m.delete
      assert m.destroyed?
    end
    
    should "respond to destroy" do
      a = SugarCRM::Account.first
      assert a.respond_to? :destroy
    end
    
    should "support saving of records with special characters in them" do
      a = SugarCRM::Account.new
      a.name = "COHEN, WEISS & SIMON LLP"
      assert a.save!
      assert a.delete
    end
    
    should "implement Base#reload!" do
      a = SugarCRM::User.find("seed_will_id")
      b = SugarCRM::User.find("seed_will_id")
      assert_not_equal 'admin', a.user_name # make sure we don't mess up admin user
      # Save the original value, so we can set it back.
      orig_last_name = a.last_name.dup
      diff_last_name = a.last_name + 'crm'
      b.last_name    = diff_last_name
      b.save!
      # Compare the two user objects
      assert_not_equal b.last_name, a.last_name
      a.reload!
      assert_equal a.last_name, b.last_name
      # Set the name back to what it was before
      b.last_name = orig_last_name
      b.save!
    end
    
    should "implement Base#update_attribute" do
      a = SugarCRM::Account.first
      orig_name = a.name
      assert a.update_attribute('name', orig_name + 'test')
      assert_not_equal orig_name, a.name
      assert a.update_attribute('name', orig_name) # revert changes
    end
    
    should "implement Base#update_attribute!" do
      a = SugarCRM::Account.first
      orig_name = a.name
      assert_nothing_raised do
        a.update_attribute!('name', orig_name + 'test')
      end
      assert_not_equal orig_name, a.name
      assert a.update_attribute('name', orig_name) # revert changes
    end
    
    should "implement Base#update_attributes" do
      a = SugarCRM::Account.first
      orig_name = a.name
      orig_street = a.billing_address_street
      assert a.update_attributes(:name => orig_name + 'test', :billing_address_street => orig_street + 'test')
      assert_not_equal orig_name, a.name
      assert_not_equal orig_street, a.billing_address_street
      assert a.update_attributes(:name => orig_name, :billing_address_street => orig_street) # revert changes
    end
    
    should "implement Base#update_attributes!" do
      a = SugarCRM::Account.first
      orig_name = a.name
      orig_street = a.billing_address_street
      assert_nothing_raised do
        a.update_attributes!(:name => orig_name + 'test', :billing_address_street => orig_street + 'test')
      end
      assert_not_equal orig_name, a.name
      assert_not_equal orig_street, a.billing_address_street
      assert a.update_attributes(:name => orig_name, :billing_address_street => orig_street) # revert changes
    end
    
    should "implement Base#persisted?" do
      a = SugarCRM::Account.new(:name => 'temp')
      assert ! a.persisted?
      a.save!
      assert a.persisted?
      a.delete
      assert ! a.persisted?
    end
  
    should "respond to #pretty_print" do 
      assert_respond_to SugarCRM::User.new, :pretty_print
    end
    
    should "return an instance's URL" do
      user = SugarCRM::User.first
      assert_equal "#{SugarCRM.session.config[:base_url]}/index.php?module=Users&action=DetailView&record=#{user.id}", user.url
    end
    
    should "respond to #blank?" do
      assert !SugarCRM::User.first.blank?
    end
    
    should "bypass validation when #save(:validate => false)" do
      u = SugarCRM::User.new
      u.last_name = "doe"
      assert u.save(:validate => false)
      assert u.delete
    end
  end

  # TODO: Fix this test so it creates the Note properly before asserting.
  context  "A SugarCRM::Note instance" do
    should "return the correct parent record with the `parent` method" do
      note = SugarCRM::Note.first
      parent = note.parent
      assert_equal note.parent_id, parent.id
      assert_equal note.parent_type.singularize, parent.class.to_s.split('::').last
    end
  end
  
end
