require 'helper'

class TestRequest < ActiveSupport::TestCase
  context "A SugarCRM::Request instance" do
    setup do
      @url    = "http://localhost/sugarcrm"
      @method = "get_entry"
      @json   =  <<-EOF 
      {
        "session": "an invalid session",
        "module_name": "Accounts",
        "name_value_list": { 
          "name": { 
            "name":  "name",        
            "value": "A Test Meeting" },
          "date_start": { 
            "name":  "date_start",  
            "value": "2011-11-23 12:03:16" },
          "description": { 
            "name":  "description", 
            "value": "&quot;OMG HAI!&quot;" }
        }
      }
      EOF
      @json.gsub!(/^\s{6}/, '')
      @request = SugarCRM::Request.new(@url, @method, @json, false)
    end
      
    should "properly escape JSON" do
      assert_equal "%7B%22hello%22%3A+%22%5C%22OMG+HAI%21%5C%22%22%7D", @request.escape('{"hello": "&quot;OMG HAI!&quot;"}')
    end
      
  end
end

