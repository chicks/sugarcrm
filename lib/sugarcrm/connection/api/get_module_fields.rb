module SugarCRM; class Connection

# Retrieves the vardef information on fields of the specified bean.  
def get_module_fields(module_name)
  login! unless logged_in?  
  json = <<-"EOF"
    {
      \"session\": \"#{@session}\"\,
      \"module_name": \"#{module_name}"
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  # TODO: Add unit test for this
  send!(:get_module_fields, json)["module_fields"]
end

alias :get_fields :get_module_fields

end; end
