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
    @modules = []
    
    namespace_module = Object::Module.new do
    end
    @namespace = "Namespace#{SugarCRM.sessions.size}"
    Session.const_set(@namespace, namespace_module)
    
    Module.register_all(self) if options[:register_modules]
  end
end; end