module SugarCRM; class Connection
  # Logs out of the Sugar user session.
  def logout
    login! unless logged_in?
    json = <<-EOF
      {
        \"user_auth\": {
          \"session\": \"#{@session}\"
        }
      }
    EOF
    json.gsub!(/^\s{8}/,'')
    response = send!(:logout, json)
  end
end; end