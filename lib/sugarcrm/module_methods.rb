module SugarCRM
  # store the namespaces that have been used to prevent namespace collision
  @@used_namespaces = []
  def self.used_namespaces
    @@used_namespaces
  end
  
  # return the namespaces linked to active sessions
  def self.namespaces
    result = []
    @@used_namespaces.each{|n|
      result << n if SugarCRM.const_defined? n
    }
    result
  end
  
  # store the various connected sessions
  # key = session.id, value = session instance
  @@sessions = {}
  def self.sessions
    @@sessions
  end
  
  def self.add_session(session)
    @@used_namespaces << session.namespace unless @@used_namespaces.include? session.namespace
    @@sessions[session.id] = session
  end
  
  def self.remove_session(session)
    @@sessions.delete(session.id)
  end
  
  def self.session
    return nil if @@sessions.size < 1
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions") if @@sessions.size > 1
    @@sessions.values.first
  end
  
  def self.connection
    return nil if @@sessions.size == 0
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: use the session instance instead of SugarCRM") if @@sessions.size > 1
    @@sessions.values.first.connection
  end
  def self.connect(url, user, pass, options={})
    session = SugarCRM::Session.new(url, user, pass, options)
    # return the namespace module
    session.namespace_const
  end
  class << self
    alias :connect! :connect
  end
  
  def self.reload!
    (raise SugarCRM::NoActiveSession, "Nothing to reload") if @@sessions.size < 1
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: call methods on the session instance instead of SugarCRM") if @@sessions.size > 1
    SugarCRM.session.reload!
  end
  
  def self.current_user
    (raise SugarCRM::NoActiveSession, "No session is active. Create a new session with 'SugarCRM.connect(...)'") if @@sessions.size < 1
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: call methods on the session instance instead of SugarCRM") if @@sessions.size > 1
    SugarCRM.session.namespace_const.current_user
  end
  
  def self.method_missing(sym, *args, &block)
    (raise SugarCRM::NoActiveSession, "No session is active. Create a new session with 'SugarCRM.connect(...)'") if @@sessions.size < 1
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: call methods on the session instance instead of SugarCRM") if @@sessions.size > 1
    SugarCRM.session.send(sym, *args, &block)
  end
  
  # If a user tries to access a SugarCRM class before they're logged in,
  # try to log in using credentials from config file.
  # This will trigger module loading,
  # and we can then attempt to return the requested class automagically
  def self.const_missing(sym)
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: use the session instance instead of SugarCRM") if @@sessions.size > 1
    # if we're logged in, modules should be loaded and available
    if SugarCRM.connection && SugarCRM.connection.logged_in?
      # if user calls (e.g.) SugarCRM::Account, delegate to SugarCRM::Namespace0::Account
      namespace_const = SugarCRM.session.namespace_const
      if namespace_const.const_defined? sym
        namespace_const.const_get(sym)
      else
        super
      end
    else
      # attempt to create a new session from credentials sotred in a config file
      begin
        Session.new
      rescue SugarCRM::MissingCredentials => e
        # unable to load necessary login credentials from config file => pass exception on
        super
      end
      # try and return the requested module
      SugarCRM.const_get(sym)
    end
  end
end