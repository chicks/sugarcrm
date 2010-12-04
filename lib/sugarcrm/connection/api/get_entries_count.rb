module SugarCRM; class Connection
# Retrieves the specified number of records in a module.
def get_entries_count(module_name, query, opts={})
  login! unless logged_in?
  options = {
    :deleted => 0
  }.merge! opts

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