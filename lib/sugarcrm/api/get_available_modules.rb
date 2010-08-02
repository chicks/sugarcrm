module SugarCRM; class Connection
  # Retrieves the list of modules available to the current user logged into the system.  
  def get_available_modules
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"
      }
    EOF
    
    json.gsub!(/^\s{6}/,'')
    get(:get_available_modules, json)["modules"]
  end
  
  alias :get_modules :get_available_modules
  
end; end