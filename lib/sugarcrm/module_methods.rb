module SugarCRM
  
  @@connection = nil
  def self.connection
    @@connection
  end
  def self.connection=(connection)
    @@connection = connection
  end
  def self.connect(url=SugarCRM::Environment.config[:base_url], user=SugarCRM::Environment.config[:username], pass=SugarCRM::Environment.config[:password], options={})
    SugarCRM::Base.establish_connection(url, user, pass, options)
  end
  class << self
    alias :connect! :connect
  end
  
  @@modules = []
  def self.modules
    @@modules
  end
  def self.modules=(modules)
    @@modules = modules
  end
  
  def self.current_user
    SugarCRM::User.find_by_user_name(connection.user)
  end
  
end