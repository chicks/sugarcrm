# This class hold an individual connection to a SugarCRM server.
# There can be several such simultaneous connections
module SugarCRM; class Session
  attr_reader :config, :connection, :extensions_path, :namespace, :namespace_const
  attr_accessor :modules
  def initialize(url, user, pass, opts={})
    options = { 
      :debug  => false,
      :register_modules => true
    }.merge(opts)
    
    @modules    = []
    @namespace  = "Namespace#{SugarCRM.used_namespaces.size}"
    @config     = {:base_url => url,:username => user,:password => pass,:options => options}
    @extensions_path = File.join(File.dirname(__FILE__), 'extensions')
    
    setup_connection
    register_namespace
    connect_and_add_session
  end
  
  # Creates a new session from the credentials present in a file
  def self.from_file(path, opts={})
    config_values = self.parse_config_file(path)
    self.from_hash(config_values[:config], opts)
  end
  
  # Creates a new session from the credentials in the hash
  def self.from_hash(hash, opts={})
    begin
      session = self.new(hash[:base_url], hash[:username], hash[:password], opts)
    rescue MissingCredentials => e
      return false
    end
    session.namespace_const
  end
  
  # Returns a hash with the content in the YAML argument file
  def self.parse_config_file(path)
    self.validate_path path
    contents = YAML.load_file(path)
    return {} unless contents
    self.symbolize_keys(contents)
  end
  
  def setup_connection
    load_config_files unless connection_info_loaded?
    raise MissingCredentials, "Missing login credentials. Make sure you provide the SugarCRM URL, username, and password" unless connection_info_loaded?
  end
  
  # re-use this session and namespace if the user wants to connect with different credentials
  def connect(url=nil, user=nil, pass=nil, opts={})
    options = { 
      :debug  => @config[:options][:debug],
      :register_modules => true
    }.merge(opts)
    
    # store the params used to connect
    {:base_url => url, :username => user, :password => pass}.each{|k,v|
      @config[k] = v  unless v.nil?
    }
    
    SugarCRM::Module.deregister_all(self)
    @connection = SugarCRM::Connection.new(@config[:base_url], @config[:username], @config[:password], options) if connection_info_loaded?
    @connection.session = self
    SugarCRM::Module.register_all(self)
    load_extensions
    true
  end
  alias :connect! :connect
  alias :reconnect :connect
  alias :reconnect! :connect
  alias :reload! :connect
  
  # log out from SugarCRM and cleanup (deregister modules, remove session, etc.)
  def disconnect
    @connection.logout
    SugarCRM::Module.deregister_all(self)
    namespace = @namespace
    SugarCRM.instance_eval{ remove_const namespace } # remove NamespaceX from SugarCRM
    SugarCRM.remove_session(self)
  end
  alias :disconnect! :disconnect
  
  def extensions_folder=(folder, dirstring=nil)
    path = File.expand_path(folder, dirstring)
    @extensions_path = path
    load_extensions
  end
  
  # load credentials from file, and (re)connect to SugarCRM
  def load_config(path)
    new_config = self.class.parse_config_file(path)
    @config[:config] = new_config[:config] if new_config
    reconnect(@config[:base_url], @config[:username], @config[:password]) if connection_info_loaded?
    @config
  end
  
  def update_config(params)
    params.each{|k,v|
      @config[k.to_sym] = v
    }
    @config
  end
  
  # lazy load the SugarCRM version we're connecting to
  def sugar_version
    @version ||= @connection.get_server_info["version"]
  end
  
  private
  # Converts all hash keys to symbols (if a hash value is itself a hash, call the method recursively)
  #   Session.symbolize_keys({"one" => 1, "two" => {"foo" => "bar"}}) # => {:one => 1, :two => {:foo => "bar"}}
  def self.symbolize_keys(hash)
    hash.inject({}){|memo,(k,v)|
      unless v.class == Hash
        memo[k.to_sym] = v
      else
        memo[k.to_sym] = self.symbolize_keys(v)
      end
      memo
    }
  end
  
  def self.validate_path(path)
    raise "Invalid path: #{path}" unless File.exists? path
  end
  
  def config_file_paths
    # see README for reasoning behind the priorization
    paths = ['/etc/sugarcrm.yaml', File.expand_path('~/.sugarcrm.yaml'), File.join(File.dirname(__FILE__), 'config', 'sugarcrm.yaml')]
    paths.insert(1, File.join(ENV['USERPROFILE'], 'sugarcrm.yaml')) if ENV['USERPROFILE']
    paths
  end
  
  def connection_info_loaded?
    return false unless @config
    @config[:base_url] && @config[:username] && @config[:password]
  end
  
  def generate_namespace_module
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
      def self.current_user
        (@session.namespace_const)::User.find_by_user_name(@session.config[:username])
      end
      def self.respond_to?(sym)
        return true if @session.respond_to? sym
        super
      end
      def self.method_missing(sym, *args, &block)
        raise unless @session.respond_to? sym
        @session.send(sym, *args, &block)
      end
    end
    # set the session: will be needed in SugarCRM::Base to call the API methods on the correct session
    namespace_module.session = self
    namespace_module
  end
  
  def load_config_files
    # see README for reasoning behind the priorization
    config_file_paths.each{|path|
      load_config path if File.exists? path
    }
  end
  
  def register_namespace
    SugarCRM.const_set(@namespace, generate_namespace_module)
    @namespace_const = SugarCRM.const_get(@namespace)
  end
  
  # load all the monkey patch extension files in the provided folder
  def load_extensions
    self.class.validate_path @extensions_path
    Dir[File.join(@extensions_path, '**', '*.rb').to_s].each { |f| load(f) }
  end  
  
  def connect_and_add_session
    connect(@config[:base_url], @config[:username], @config[:password], @config[:options])
    SugarCRM.add_session(self)
  end
  
end; end