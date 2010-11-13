module SugarCRM; class Connection
# Retrieves a collection of beans that are related 
# to the specified bean and, optionally, returns 
# relationship data
def get_relationships(module_name, id, related_to, opts={})
  login! unless logged_in?
  options = { 
    :query => '',
    :fields => [], 
    :link_fields => [], 
    :deleted => ''
  }.merge! opts  
  
  related_module = related_to.classify
  
  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"module_name\": \"#{module_name}\"\,
      \"module_id\": \"#{id}\"\,
      \"link_field_name\": \"#{related_to.downcase}\"\,
      \"related_module_query\": \"#{options[:query]}\"\,
      \"related_fields\": #{resolve_fields(related_module, options[:fields])}\,
      \"related_module_link_name_to_fields_array\": #{options[:link_fields].to_json}\,
      \"deleted\": #{options[:deleted]}
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  SugarCRM::Response.new(send!(:get_relationships, json)).to_obj
end

alias :get_relationship :get_relationships

end; end