module SugarCRM; class Connection
  # Returns server information such as version, flavor, and gmt_time.
  def get_server_info
    login! unless logged_in?
    connection.send!(:get_server_info, "")
  end
end; end