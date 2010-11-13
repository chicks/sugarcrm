module SugarCRM; class Connection
  # Sets multiple relationships between two SugarBeans.
  def set_relationships(module_names, module_ids, link_field_names, related_ids)
    login! unless logged_in?
    
    [module_names, module_ids, link_field_names, related_ids].each do |arg|
      raise ArgumentError, "argument must be an Array" unless arg.class == Array
    end
    
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_names\": \"#{module_names.to_json}\"\,
        \"module_ids\": #{module_ids.to_json}\,
        \"link_field_names\": #{link_field_names.to_json}\,
        \"related_ids\": #{link_field_name.to_json}   
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_relationships, json)
  end
end; end