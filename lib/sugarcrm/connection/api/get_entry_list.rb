module SugarCRM; class Connection
# Retrieve a list of SugarBeans.  This is the primary method for getting 
# a list of SugarBeans using the REST API.
def get_entry_list(module_name, query, opts={})
  login! unless logged_in?  
  options = {
    :order_by => '', 
    :offset => '', 
    :fields => [], 
    :link_fields => [], 
    :max_results => '', 
    :deleted => ''
  }.merge! opts

  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"module_name\": \"#{module_name}\"\,
      \"query\": \"#{query}\"\,
      \"order_by\": \"#{options[:order_by]}\"\,
      \"offset\": \"#{options[:offset]}\"\,
      \"select_fields\": #{resolve_fields(module_name, options[:fields])}\,
      \"link_name_to_fields_array\": #{options[:link_fields].to_json}\,
      \"max_results\": \"#{options[:max_results]}\"\,
      \"deleted\": #{options[:deleted]}
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  SugarCRM::Response.new(send!(:get_entry_list, json))
  #send!(:get_entry_list, json)
end
end; end