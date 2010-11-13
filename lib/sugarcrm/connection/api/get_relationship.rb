module SugarCRM; class Connection
# Retrieves a collection of beans that are related 
# to the specified bean and, optionally, returns 
# relationship data
def get_relationship(module_name, id, related_to, options={})
  login! unless logged_in?
  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"module_name\": \"#{module_name}\"\,
      \"module_ids\": \"#{id}\"\,
      \"link_field_name\": \"#{related_to.downcase}\"\,
      \"related_module_query\": \"#{options[:related_module_query]}\"\,
      \"related_fields\": #{options[:related_fields].to_json}\,
      \"related_module_link_name_to_fields_array\": #{options[:related_link_fields].to_json}\,
      \"deleted\": #{options[:deleted]}
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  send!(:get_relationship, json)
end

alias :get_relationships :get_relationship

end; end