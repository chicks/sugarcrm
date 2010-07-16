module SugarCRM; class Base
  def get_entry(module_name, id, options={})
    login! unless logged_in?
    { :fields => [], 
      :link_fields => [], 
    }.merge! options

    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"module_name\": \"#{module_name}\"\,
        \"id\": \"#{id}\"\,
        \"select_fields\": #{options[:fields].to_json}\,
      }
    EOF
    
    placeholder = <<-EOF
        \"select_fields\": [\"name\"]
        \"link_name_to_fields_array\": \"#{options[:link_fields]}\"\,
    EOF
    
    json.gsub!(/^\s{6}/,'')
    get(:get_entry, json)
  end
end; end