module SugarCRM; class Connection
  # Creates or updates a single SugarBean.
  def set_entry(module_name, name_value_list)
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"name_value_list\": #{name_value_list.to_json}
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_entry, json)
  end
end; end