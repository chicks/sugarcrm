module SugarCRM; class Connection
  # Performs a mail merge for the specified campaign.
  def set_campaign_merge(targets, campaign_id)
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"\,
        \"targets\": #{targets.to_json}\,
        \"campaign-id\": \"#{campaign_id}\"
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:set_campaign_merge, json)
  end
end; end