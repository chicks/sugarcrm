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
  def self.connect(url, user, pass, options={})
    session = SugarCRM::Session.new(url, user, pass, options)
    # return the namespace module
    SugarCRM.const_get(session.namespace)
  end
  class << self
    alias :connect! :connect
  end
  
  def self.current_user
    raise unless @@sessions.size == 1
    SugarCRM.const_get(@@sessions.first.namespace).current_user
  end
  
  def self.method_missing(sym, *args, &block)
    raise unless @@sessions.size == 1
    @@sessions.first.send(sym, *args, &block)
  end
  
  # If a user tries to access a SugarCRM class before they're logged in,
  # try to log in using credentials from config file.
  # This will trigger module loading,
  # and we can then attempt to return the requested class automagically
  def self.const_missing(sym)
    raise if @@sessions.size > 1
    # if we're logged in, modules should be loaded and available
    if SugarCRM.connection && SugarCRM.connection.logged_in?
      super
    else
      # attempt to create a new session from credentials sotred in a config file
      begin
        Session.new
      rescue MissingCredentials => e
        # unable to load ncessary login credentials from config file => pass exception on
        super
      end
      # try and return the requested module
      SugarCRM.const_get(sym)
    end
  end
end