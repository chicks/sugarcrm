module SugarCRM; class Connection
  # Sets a single relationship between two SugarBeans.
  def set_relationship(module_name, module_id, link_field_name, related_ids)
    login! unless logged_in?
    raise ArgumentError, "related_ids must be an Array" unless related_ids.class == Array
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"module_id\": #{module_id}\,
        \"link_field_name\": #{link_field_name}\,
        \"related_ids\": #{link_field_name.to_json}   
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_relationship, json)
  end
end; end