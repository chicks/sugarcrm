module SugarCRM; class Connection
  # Returns the ID, module name and fields for specified modules. 
  # Supported modules are Accounts, Bugs, Calls, Cases, Contacts, 
  # Leads, Opportunities, Projects, Project Tasks, and Quotes.
  def search_by_module(search_string, modules, options={})
    login! unless logged_in?
    
    { :offset => nil, 
      :max_results => nil, 
    }.merge! options
    
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"search_string\": \"#{search_string}\"\,
        \"modules\": \"#{modules}\"\,
        \"offset\": #{options[:offset]}\,
        \"max_results\": #{options[:max_results]}
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:search_by_module, json)
  end
end; end