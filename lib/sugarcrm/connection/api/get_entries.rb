module SugarCRM; class Connection
# Retrieve a list of SugarBeans by ID.  This method will not 
# work with the report module.
def get_entries(module_name, ids, options={})
  login! unless logged_in?
  {
    :fields => '', 
    :link_fields => [], 
  }.merge! options

  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"module_name\": \"#{module_name}\"\,
      \"ids\": #{ids.to_json}\,
      \"select_fields\": #{options[:fields].to_json}\,
      \"link_name_to_fields_array\": #{options[:link_fields].to_json}\,
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  SugarCRM::Response.new(send!(:get_entries, json))
  #send!(:get_entries, json)
end
end; end