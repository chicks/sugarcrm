module SugarCRM; class Connection
  # Retrieves the ID of the default team of the user 
  # who is logged into the current session.
  def get_user_team_id
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:get_user_team_id, json)
  end
end; end