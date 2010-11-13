module SugarCRM; class Connection
  # Performs a seamless login during synchronization.
  def seamless_login
    login! unless logged_in?
    json = <<-EOF
      {
        \"session\": \"#{@session}\"
      }
    EOF
    json.gsub!(/^\s{8}/,'')
    response = send!(:seamless_login, json)
  end
end; end