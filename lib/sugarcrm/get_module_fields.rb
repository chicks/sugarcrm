module SugarCRM; class Base
  
def get_module_fields(module_name)
  login! unless logged_in?
  json = <<-"EOF"
    {
      \"session\": \"#{@session}\"\,
      \"module_name": \"#{module_name}"
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  get(:get_module_fields, json)
end

end; end
