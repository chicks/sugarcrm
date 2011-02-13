# This class hold an individual connection to a SugarCRM server.
# There can be several such simultaneous connections
module SugarCRM; class Session
  attr_reader :connection, :namespace
  attr_accessor :modules
  def initialize(url, user, pass, opts={})
    options = { 
      :debug  => false,
      :register_modules => true
    }.merge(opts)
    @connection = SugarCRM::Connection.new(url, user, pass, opts)
    @connection.session_instance = self
    @modules = []
    @namespace = "Namespace#{SugarCRM.sessions.size}"
    
    @base_url = url
    @username = user
    @password = pass
    
    # Create a new module to have a separate namespace in which to register the SugarCRM modules.
    # This will prevent issues with modules from separate SugarCRM instances colliding within the same namespace
    # (e.g. 2 SugarCRM instances where only one has custom fields on the Account module)
    namespace_module = Object::Module.new do
      @session = nil
      def self.session
        @session
      end
      def self.session=(sess)
        @session = sess
      end
    end
    # set the session: will be needed in SugarCRM::Base to call the API methods on the correct session
    namespace_module.session = self
    
    SugarCRM.const_set(@namespace, namespace_module)
    
    Module.register_all(self) if options[:register_modules]
  end
end; end