module SugarCRM; class Connection
# Retrieves a list of report entries based on specified report IDs.
def get_report_entries(ids, options={})
  login! unless logged_in?
  {
    :select_fields => '', 
  }.merge! options

  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"ids\": #{ids.to_json}\,
      \"select_fields\": \"#{select_fields}\"
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  send!(:get_report_entries, json)
end
end; end