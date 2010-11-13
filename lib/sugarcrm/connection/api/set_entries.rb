module SugarCRM; class Connection
  # Creates or updates a list of SugarBeans.
  def set_entries(module_name, name_value_lists)
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"name_value_list\": #{name_value_lists.to_json}
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_entries, json)
  end
end; end