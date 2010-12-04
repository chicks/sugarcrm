module SugarCRM; class Connection
  # Returns the ID, module name and fields for specified modules. 
  # Supported modules are Accounts, Bugs, Calls, Cases, Contacts, 
  # Leads, Opportunities, Projects, Project Tasks, and Quotes.
  def search_by_module(search_string, modules, ops={})
    login! unless logged_in?
    
    options = { 
      :offset => nil, 
      :limit => nil, 
    }.merge! opts
    
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"search_string\": \"#{search_string}\"\,
        \"modules\": \"#{modules}\"\,
        \"offset\": #{options[:offset]}\,
        \"max_results\": #{options[:limit]}
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:search_by_module, json)
  end
end; end