require 'helper'

class TestSugarCRM < Test::Unit::TestCase
  context "A SugarCRM::Base instance" do
    
    should "establish a connection when Base#establish_connection" do
      # Base#establish_connection was called automatically when loading config file containing connection params
      assert SugarCRM.connection.connected?
    end
  
    should "return the module name" do
      assert_equal "Users", SugarCRM::User._module.name
    end
    
    should "return the module fields" do
      assert_instance_of ActiveSupport::HashWithIndifferentAccess, SugarCRM::Account._module.fields
    end
    
    should "responsd to self#methods" do
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
      assert_instance_of ActiveSupport::HashWithIndifferentAccess, SugarCRM::User.attributes_from_module
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

    should "always return an Array when :all" do
      users = SugarCRM::User.all(:limit => 10)
      assert_instance_of Array, users
      users = SugarCRM::User.find(:all, :conditions => {:user_name => '= admin'})
      assert_instance_of Array, users
      assert users.length == 1
      users = SugarCRM::User.find(:all, :conditions => {:user_name => '= invalid_user_123'})
      assert_instance_of Array, users
      assert users.length == 0
    end

    should "create, modify, and delete a record" do
      u = SugarCRM::User.new
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
    end
    
    should "support finding first instance (sorted by attribute)" do
      account = SugarCRM::Account.first({
       	:order_by => 'name'
      })
      assert_instance_of SugarCRM::Account, account
    end
    
    should "support finding last instance (sorted by attribute)" do
      expected_account = SugarCRM::Account.first({:order_by => 'name DESC'})
      account = SugarCRM::Account.last({:order_by => 'name'})
      assert_equal expected_account.id, account.id
      
      expected_account = SugarCRM::Account.first({:order_by => 'name DESC'})
      account = SugarCRM::Account.last({:order_by => 'name ASC'})
      assert_equal expected_account.id, account.id
      
      expected_account = SugarCRM::Account.first({:order_by => 'name ASC'})
      account = SugarCRM::Account.last({:order_by => 'name DESC'})
      assert_equal expected_account.id, account.id
    end
    
    should "support finding last instance (most recently modified)" do
      expected_account = SugarCRM::Account.first({:order_by => 'date_modified DESC'})
      account = SugarCRM::Account.last
      assert_equal expected_account.id, account.id
    end
    
    should "support returning only certain fields" do
      user = SugarCRM::User.first(:fields => [:first_name, :department])
      assert_instance_of SugarCRM::User, user
    end
    
    should "raise a RuntimeError when searching for last instance with multiple order clauses" do
      assert_raise(RuntimeError){ SugarCRM::Account.last({:order_by => 'name, id DESC'}) }
    end
    
    should "raise a RuntimeError when searching for last instance if order clause has weird format" do
      assert_raise(RuntimeError){ SugarCRM::Account.last({:order_by => 'name id DESC'}) }
      assert_raise(RuntimeError){ SugarCRM::Account.last({:order_by => 'name DESC id'}) }
    end
    
    should "support searching based on conditions" do
      accounts = SugarCRM::Account.all({
        :conditions => { :billing_address_postalcode => ["> '70000'", "< '79999'" ] },
        :limit => '10',
       	:order_by => 'billing_address_postalcode'
      })
      assert_instance_of SugarCRM::Account, accounts.first
    end
    
    should "support searching based on SQL operators" do
      accounts = SugarCRM::Account.all({
        :conditions => { :name => "LIKE '%Inc%'" }
      })
      assert accounts
      assert_instance_of SugarCRM::Account, accounts.first
    end
    
    should "return an an instance of itself when sent #find(id)" do
      assert_instance_of SugarCRM::User, SugarCRM::User.find(1)
    end
    
    should "receive a response containing all fields when sent #get_entry" do
      u = SugarCRM::User.find(1)
      assert_equal u.user_name, "admin"
    end
    
    should "return an array of records when sent #find([id1, id2, id3])" do
      users = SugarCRM::User.find(["seed_sarah_id", 1])
      assert_equal "admin", users.last.user_name
    end
    
    # test Base#find_by_sql edge case
    should "return an array of records with small limit and an offset of 0" do
      accounts = SugarCRM::Account.all(:limit => 3, :offset => 0)
      assert_equal 3, accounts.size
    end
    
    # test Base#find_by_sql standard case
    should "return an array of records with high limit" do
      accounts = SugarCRM::Account.all(:limit => 12)
      assert_equal 12, accounts.size
    end
    
    should "return an array of records when using :order_by, :limit, and :offset options" do
      accounts = SugarCRM::Account.all(:order_by => 'name', :limit => 3, :offset => 10)
      accounts_api = SugarCRM.connection.get_entry_list('Accounts', '1=1', :order_by => 'name', :limit => 3, :offset => 10)
      assert_equal accounts_api, accounts
    end
    
    should "return an array of records working around a SugarCRM bug when :limit > :offset" do
      accounts = SugarCRM::Account.all(:order_by => 'name', :limit => 10, :offset => 2)
      assert_equal 10, accounts.size
    end
    
    should "return an array of 1 record with :limit => 1, :offset => 1" do
      accounts = SugarCRM::Account.all(:order_by => 'name', :limit => 1, :offset => 1)
      assert_equal 1, accounts.size
    end
    
    should "ignore :offset => 0" do
      accounts = SugarCRM::Account.all(:order_by => 'name', :limit => 3)
      accounts_offset = SugarCRM::Account.all(:order_by => 'name', :limit => 3, :offset => 0)
      assert_equal accounts, accounts_offset
    end
    
    should "compute offsets correctly" do
      accounts = SugarCRM::Account.all(:order_by => 'name', :limit => 10, :offset => 3)
      accounts_first_slice = SugarCRM::Account.all(:order_by => 'name', :limit => 5, :offset => 3)
      accounts_second_slice = SugarCRM::Account.all(:order_by => 'name', :limit => 5, :offset => 8)
      assert_equal accounts, accounts_first_slice.concat(accounts_second_slice)
    end
    
    should "return an instance of User when sent User#find_by_username" do
      u = SugarCRM::User.find_by_user_name("sarah")
      assert_equal "sarah@example.com", u.email_addresses.first.email_address
    end
    
    should "create or retrieve a record when #find_or_create_by_name" do
      a = SugarCRM::Account.find_or_create_by_name("Really Important Co. Name")
      assert_instance_of SugarCRM::Account, a
      assert !a.new?
      b = SugarCRM::Account.find_or_create_by_name("Really Important Co. Name")
      assert a == b
      assert a.delete
    end
    
    should "support saving of records with special characters in them" do
      a = SugarCRM::Account.new
      a.name = "COHEN, WEISS & SIMON LLP"
      assert a.save!
      assert a.delete
    end
  end
  
end
