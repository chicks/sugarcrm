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
  
  # If a user tries to access a SugarCRM class before they're logged in,
  # try to log in using credentials from config file.
  # This will trigger module loading,
  # and we can then attempt to return the requested class automagically
  def self.const_missing(sym)
    # initialize environment (will log user in if credentials present in config file)
    SugarCRM::Environment.instance
    # try and return the requested module
    SugarCRM.const_get(sym)
  end
end