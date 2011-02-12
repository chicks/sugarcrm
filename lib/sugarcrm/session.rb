# This class hold an individual connection to a SugarCRM server.
# There can be several such simultaneous connections
module SugarCRM; class Session
  attr_reader :connection
  def initialize(url, user, pass, opts={})
    options = { 
      :debug  => false,
      :register_modules => true
    }.merge(opts)
    @connection = SugarCRM::Connection.new(url, user, pass, opts)
    Module.register_all(self) if options[:register_modules]
  end
end; end