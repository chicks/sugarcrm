require 'singleton'

module SugarCRM; class Environment
  include Singleton
  
  attr_reader :config
  
  def initialize
    @config = {}
    
    # see README for reasoning behind the priorization
    ['/etc/sugarcrm.yaml', File.expand_path('~/.sugarcrm.yaml'), File.join(File.dirname(__FILE__), 'config', 'sugarcrm.yaml')].each{|path|
      load_config path if File.exists? path
    }
    extensions_folder = File.join(File.dirname(__FILE__), 'extensions')
    SugarCRM::Base.establish_connection(@config[:base_url], @config[:username], @config[:password], {:load_environment => false}) if SugarCRM.connection.nil? && connection_info_loaded?
  end
  
  def connection_info_loaded?
    @config[:base_url] && @config[:username] && @config[:password]
  end
  
  def load_config(path)
    validate_path path
    config = YAML.load_file(path)
    if config && config["config"]
      config["config"].each{|k,v|
        @config[k.to_sym] = v
      }
    end
    @config
  end
  
  def update_config(params)
    params.each{|k,v|
      @config[k.to_sym] = v
    }
    @config
  end
  
  # load all the monkey patch extension files in the provided folder
  def extensions_folder=(folder, dirstring=nil)
    validate_path folder
    path = File.expand_path(folder, dirstring)
    Dir[File.join(path, '**', '*.rb').to_s].each { |f| load(f) }
  end
  
  def self.method_missing(method_id, *args, &block)
    self.instance.send(method_id, *args, &block)
  end
  
  private
  def validate_path(path)
    raise "Invalid path: #{path}" unless File.exists? path
  end
end; end