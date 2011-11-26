require 'helper'

class TestSetEntry < ActiveSupport::TestCase
  context "A SugarCRM.connection" do
    should "set values on an Bean with #set_entry" do
      
      name_value_list = { 
        "name"        => { "name" => "name",        "value" => "A Test Meeting" },
        "date_start"  => { "name" => "date_start",  "value" => "2011-11-23 12:03:16" },
        "description" => { "name" => "description", "value" => "RT @bumblebeenie &quot;It's Childish Gambino, home girl drop it like the Nasdaq&quot; Are you serious bro?" }
      }
      meeting = SugarCRM.connection.set_entry("Meetings", name_value_list)
    end
  end
end