module SugarCRM; class Connection
# Retrieves a list of report entries based on specified report IDs.
def get_report_entries(ids, opts={})
  login! unless logged_in?
  options = {:select_fields => ''}.merge! opts

  json = <<-EOF
    {
      \"session\": \"#{@session}\"\,
      \"ids\": #{ids.to_json}\,
      \"select_fields\": \"#{options[:select_fields].to_json}\"
    }
  EOF
  json.gsub!(/^\s{6}/,'')
  send!(:get_report_entries, json)
end
end; end