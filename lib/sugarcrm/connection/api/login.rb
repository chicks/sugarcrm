module SugarCRM; class Connection
  # Logs the user into the Sugar application.
  def login
    connect! unless connected?
    json = <<-EOF
      {
        \"user_auth\": {
          \"user_name\": \"#{@user}\"\,
          \"password\": \"#{OpenSSL::Digest::MD5.new(@pass)}\"\,
          \"version\": \"2\"\,
        },
        \"application\": \"\"
      }
    EOF
    json.gsub!(/^\s{8}/,'')
    response = send!(:login, json)
  end
end; end