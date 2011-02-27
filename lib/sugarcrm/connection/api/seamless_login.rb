module SugarCRM; class Connection
  # Performs a seamless login during synchronization.
  def seamless_login
    login! unless logged_in?
    json = <<-EOF
      {
        "session": "#{@sugar_session_id}"
      }
    EOF
    json.gsub!(/^\s{6}/,'')
    response = send!(:seamless_login, json)
  end
end; end