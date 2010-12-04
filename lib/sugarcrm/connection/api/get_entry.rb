module SugarCRM; class Connection
  # Retrieves a single SugarBean based on the ID.
  def get_entry(module_name, id, opts={})
    login! unless logged_in?
    options = { 
      :fields => [], 
      :link_fields => [], 
    }.merge! opts
    
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"id\": \"#{id}\"\,
        \"select_fields\": #{resolve_fields(module_name, options[:fields])}\,
        \"link_name_to_fields_array\": #{options[:link_fields]}\,
      }
    EOF
        
    json.gsub!(/^\s{6}/,'')
    SugarCRM::Response.handle(send!(:get_entry, json))
  end
end; end