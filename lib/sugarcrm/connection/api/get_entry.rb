module SugarCRM; class Connection
  # Retrieves a single SugarBean based on the ID.
  def get_entry(module_name, id, options={})
    login! unless logged_in?
    { :fields => [], 
      :link_fields => [], 
    }.merge! options
    
    # FIXME: This is to work around a bug in SugarCRM 6.0
    # where no fields are returned if no fields are specified
    if options[:fields].length == 0
      obj = SugarCRM.const_send!(module_name.singularize).new
      options[:fields] = obj.module_fields.keys
    end
    
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"id\": \"#{id}\"\,
        \"select_fields\": #{options[:fields].to_json}\,
        \"link_name_to_fields_array\": #{options[:link_fields]}\,
      }
    EOF
        
    json.gsub!(/^\s{6}/,'')
    SugarCRM::Response.new(send!(:get_entry, json))
  end
end; end