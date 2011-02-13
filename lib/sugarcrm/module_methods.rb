module SugarCRM
  @@sessions = []
  def self.sessions
    @@sessions
  end
  
  def self.connection
    return nil if @@sessions.size == 0
    raise if @@sessions.size > 1
    @@sessions.first.connection
  end
  def self.connect(url=SugarCRM::Environment.config[:base_url], user=SugarCRM::Environment.config[:username], pass=SugarCRM::Environment.config[:password], options={})
    session = SugarCRM::Session.new(url, user, pass, options)
    @@sessions << session
    # return the namespace module
    SugarCRM.const_get(session.namespace)
  end
  class << self
    alias :connect! :connect
  end
  
  def self.current_user
    SugarCRM::User.find_by_user_name(SugarCRM::Environment.config[:username])
  end
  
  def self.method_missing(sym, *args, &block)
    raise if @@sessions.size > 1
    @@sessions.first.send(sym, *args, &block)
  end
  
  # If a user tries to access a SugarCRM class before they're logged in,
  # try to log in using credentials from config file.
  # This will trigger module loading,
  # and we can then attempt to return the requested class automagically
  def self.const_missing(sym)
    # if we're logged in, modules should be loaded and available
    if SugarCRM.connection && SugarCRM.connection.logged_in?
      super
    else
      # here, we initialize the environment (which happens on any method call, if singleton hasn't already been initialized)
      # initializing the environment will log user in if credentials present in config file
      # if it isn't possible to log in and access modules, pass the exception on
      super unless SugarCRM::Environment.connection_info_loaded?
      # try and return the requested module
      SugarCRM.const_get(sym)
    end
  end
end