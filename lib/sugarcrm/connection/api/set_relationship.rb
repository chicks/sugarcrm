module SugarCRM; class Connection
  # Sets a single relationship between two SugarBeans.
  def set_relationship(module_name, module_id, link_field_name, related_ids, opts={})
    login! unless logged_in?
    options = { 
      :name_value_list => [], 
      :delete => 0, 
    }.merge! opts
    raise ArgumentError, "related_ids must be an Array" unless related_ids.class == Array
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"module_id\": \"#{module_id}\"\,
        \"link_field_name\": \"#{link_field_name}\"\,
        \"related_ids\": #{related_ids.to_json}\,
        \"name_value_list\": #{options[:name_value_list].to_json}\,
        \"delete\": #{options[:delete]}  
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_relationship, json)
  end
end; end