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
  # key = session.object_id, value = session instance
  @@sessions = {}
  def self.sessions
    @@sessions
  end
  
  def self.add_session(session)
    @@used_namespaces << session.namespace unless @@used_namespaces.include? session.namespace
    @@sessions[session.object_id] = session
  end
  
  def self.remove_session(session)
    @@sessions.delete(session.object_id)
  end
  
  def self.session
    return nil if @@sessions.size < 1
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: use the session namespace instead of SugarCRM") if @@sessions.size > 1
    @@sessions.values.first
  end
  
  def self.connection
    return nil unless self.session
    self.session.connection
  end
  
  def self.connect(url, user, pass, options={})
    session = SugarCRM::Session.new(url, user, pass, options)
    # return the namespace module
    session.namespace_const
  end
  
  class << self
    alias :connect! :connect
  end
  
  def respond_to?(sym)
    return true if @@sessions.size == 1 && SugarCRM.session.namespace_const.respond_to?(sym)
    super
  end
  
  def self.method_missing(sym, *args, &block)
    (raise SugarCRM::NoActiveSession, "No session is active. Create a new session with 'SugarCRM.connect(...)'") if @@sessions.size < 1
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: call methods on the session namespace instead of SugarCRM") if @@sessions.size > 1
    if SugarCRM.session.namespace_const.respond_to? sym
      SugarCRM.session.namespace_const.send(sym, *args, &block)
    else
      super
    end
  end
  
  # If a user tries to access a SugarCRM class before they're logged in,
  # try to log in using credentials from config file.
  # This will trigger module loading,
  # and we can then attempt to return the requested class automagically
  def self.const_missing(sym)
    (raise SugarCRM::MultipleSessions, "There are multiple active sessions: use the session namespace instead of SugarCRM") if @@sessions.size > 1
    # make sure we have an active session
    begin
      Session.new unless SugarCRM.connection && SugarCRM.connection.logged_in?
    rescue SugarCRM::MissingCredentials => e
      # unable to load necessary login credentials from config file => pass exception on
      super
    end
    
    # if user calls (e.g.) SugarCRM::Account, delegate to SugarCRM::Namespace0::Account
    namespace_const = SugarCRM.session.namespace_const
    if namespace_const.const_defined? sym
      namespace_const.const_get(sym)
    else
      super
    end
  end
end