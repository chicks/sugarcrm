module SugarCRM; class Connection
  # Retrieves a collection of beans that are related 
  # to the specified bean and, optionally, returns 
  # relationship data
  # Ajay Singh --> changed as per our equirment.
  # "related_fields": #{resolve_related_fields(module_name, related_to)},

  def get_relationships(module_name, id, related_to, opts={})
    login! unless logged_in?
    options = { 
      :query => '',
      :fields => [], 
      :link_fields => [],
      :related_fields => [], 
      :deleted => 0
    }.merge! opts  

    json = <<-EOF
      {
        "session": "#{@sugar_session_id}",
        "module_name": "#{module_name}",
        "module_id": "#{id}",
        "link_field_name": "#{related_to.downcase}",
        "related_module_query": "#{options[:query]}",
        "related_fields": #{((options and options[:related_fields].present?) ? options[:related_fields] : resolve_related_fields(module_name, related_to) ).to_json},     
        "related_module_link_name_to_fields_array": #{options[:link_fields].to_json},
        "deleted": #{options[:deleted]}
      }
    EOF
    #puts "#{json}"
    json.gsub!(/^\s{6}/,'')
    SugarCRM::Response.new(send!(:get_relationships, json), @session, {:always_return_array => true}).to_obj
  end
  alias :get_relationship :get_relationships
end; end
