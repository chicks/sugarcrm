module SugarCRM; class Connection
# Retrieves the specified number of records in a module.
def get_entries_count(module_name, query, options={})
  login! unless logged_in?
  {
    :deleted => 0, 
  }.merge! options

  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"module_name\": \"#{module_name}\"\,
      \"query\": \"#{query}\"\,
      \"deleted\": #{options[:deleted]}
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  send!(:get_entries_count, json)
end
end; end