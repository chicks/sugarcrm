# This class hold an individual connection to a SugarCRM server.
# There can be several such simultaneous connections
module SugarCRM; class Session
  attr_reader :config, :connection, :id, :namespace, :namespace_const
  attr_accessor :modules
  def initialize(url=nil, user=nil, pass=nil, opts={})
    options = { 
      :debug  => false,
      :register_modules => true
    }.merge(opts)
    @id = nil
    @modules = []
    @namespace = "Namespace#{SugarCRM.sessions.size}"
    
    @config = {
      :base_url => url,
      :username => user,
      :password => pass
    }
    
    unless connection_info_loaded?
      # see README for reasoning behind the priorization
      config_file_paths.each{|path|
        load_config path if File.exists? path
      }
    end
    
    raise MissingCredentials, "Missing login credentials. Make sure you provide the SugarCRM URL, username, and password" unless connection_info_loaded?
    
    @connection = SugarCRM::Connection.new(url, user, pass, opts)
    @connection.session = self
    @id = @connection.session_id
    
    extensions_folder = File.join(File.dirname(__FILE__), 'extensions')
    
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
    end
    # set the session: will be needed in SugarCRM::Base to call the API methods on the correct session
    namespace_module.session = self
    
    SugarCRM.const_set(@namespace, namespace_module)
    @namespace_const = SugarCRM.const_get(@namespace)
    
    Module.register_all(self) if options[:register_modules]
    
    SugarCRM.sessions << self
  end
  
  # create a new session from the credentials present in a file
  def self.new_from_file(path, opts={})
    config = load_and_parse_config(path)
    begin
      self.new(config[:base_url], config[:username], config[:password], opts)
    rescue MissingCredentials => e
      return false
    end
  end
  
  # load all the monkey patch extension files in the provided folder
  def extensions_folder=(folder, dirstring=nil)
    self.class.validate_path folder
    path = File.expand_path(folder, dirstring)
    Dir[File.join(path, '**', '*.rb').to_s].each { |f| load(f) }
  end
  
  # load credentials from file, and (re)connect to SugarCRM
  def load_config(path)
    @config = self.class.load_and_parse_config(path)
    @connection = SugarCRM::Connection.new(@config[:base_url], @config[:username], @config[:password]) if connection_info_loaded?
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
  def self.load_and_parse_config(path)
    validate_path path
    hash = {}
    config = YAML.load_file(path)
    if config && config["config"]
      config["config"].each{|k,v|
        hash[k.to_sym] = v
      }
    end
    hash
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
    @config[:base_url] && @config[:username] && @config[:password]
  end
end; end