module SugarCRM; class Connection
  # Retrieves the list of modules available to the current user logged into the system.  
  def get_available_modules
    login! unless logged_in?
    json = <<-EOF
      {
        "session": "#{@sugar_session_id}"
      }
    EOF
    
    json.gsub!(/^\s{6}/,'')
    mods = send!(:get_available_modules, json)["modules"]
    modules = []
    mods.each do |mod|
      modules << Module.new(@session, mod)
    end
    modules
  end
  
  alias :get_modules :get_available_modules
  
end; end