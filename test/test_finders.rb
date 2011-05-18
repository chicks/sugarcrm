require 'helper'

class TestFinders < ActiveSupport::TestCase
  context "A SugarCRM::Base instance" do
    should "always return an Array when :all" do
      users = SugarCRM::User.all(:limit => 10)
      assert_instance_of Array, users
      users = SugarCRM::User.find(:all, :conditions => {:user_name => "= #{users.first.user_name}"})
      assert_instance_of Array, users
      assert_equal 1, users.length
      users = SugarCRM::User.find(:all, :conditions => {:user_name => '= invalid_user_123'})
      assert_instance_of Array, users
      assert users.length == 0
    end
    
    should "support finding first instance with default sort order (for module using date_entered as creation date)" do
      expected_account = SugarCRM::Account.first({:order_by => 'date_entered'})
      account = nil
      assert_nothing_raised do
        account = SugarCRM::Account.first
      end
      assert_equal expected_account.id, account.id
    end
    
    should "support finding first instance with default sort order (for module using date_created as creation date)" do
      expected_email = SugarCRM::EmailAddress.first({:order_by => 'date_created'})
      email = nil
      assert_nothing_raised do
        email = SugarCRM::EmailAddress.first
      end
      assert_equal expected_email.id, email.id
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
    
    should "support finding last instance with symbol as :order_by option" do
      expected_account = SugarCRM::Account.first({:order_by => 'id DESC'})
      account = SugarCRM::Account.last({:order_by => :id})
      assert_equal expected_account.id, account.id
    end
    
    should "support finding last instance (last created)" do
      expected_account = SugarCRM::Account.first({:order_by => 'date_entered DESC'})
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
        :limit => 2,
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
      assert_not_nil u.user_name
    end
    
    should "return an array of records when sent #find([id1, id2, id3])" do
      users = SugarCRM::User.find(["seed_sarah_id", 1])
      assert_not_nil users.last.user_name
    end
    
    # test Base#find_by_sql edge case
    should "return an array of records with small limit and an offset of 0" do
      accounts = SugarCRM::Account.all(:limit => 3, :offset => 0)
      assert_equal 3, accounts.size
    end
    
    # test Base#find_by_sql edge case: force slize size to vary up and down
    should "return an array of records with small offset and a limit greater than 5 but not divisible by 5" do
      accounts = SugarCRM::Account.all(:limit => 13, :offset => 2)
      assert_equal 13, accounts.size
    end
    
    # test Base#find_by_sql standard case
    should "return an array of records with high limit" do
      accounts = SugarCRM::Account.all(:limit => 12)
      assert_equal 12, accounts.size
    end
    
    should "accept a block" do
      # try small limit which will return result on the first result slice (and call yield block only once)
      count = 0
      assert_nothing_raised do
        SugarCRM::Account.all(:limit => 2){|a|
          count += 1
        }
      end
      assert_equal 2, count
      
      # try larger limit which will require multiple result slices to be fetched and yielded individually (yield block called for each result slice)
      count = 0
      assert_nothing_raised do
        SugarCRM::Account.all(:limit => 12){|a|
          count += 1
        }
      end
      assert_equal 12, count
    end
    
    should "retrieve all records (with no limit option) correctly" do
      count = 0
      SugarCRM::Account.all{|a|
        count += 1
      }
      assert_equal SugarCRM::Account.count, count
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
  end
end
