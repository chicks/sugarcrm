module SugarCRM; class Connection
  # Returns the ID of the user who is logged into the current session.
  def get_user_id
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    send!(:get_user_id, json)
  end
end; end