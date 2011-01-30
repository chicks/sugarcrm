require 'singleton'

module SugarCRM; class Environment
  include Singleton
  
  attr_reader :config
  
  def initialize
    @config = {}
    
    load_config File.join(File.dirname(__FILE__), 'config', 'config.yaml')
    monkey_patch_folder = File.join(File.dirname(__FILE__), 'monkey_patches')
  end
  
  def load_config(path)
    validate_path path
    config = YAML.load_file(path)
    if config && config["config"]
      config["config"].each{|k,v|
        @config[k.to_sym] = v
      }
    end
  end
  
  # load all the monkey patch files in the provided folder
  def monkey_patch_folder=(folder, dirstring=nil)
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