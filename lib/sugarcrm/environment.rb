module SugarCRM; class Environment
  # load all the monkey patch files in the provided folder
  def self.monkey_patch_folder=(folder, dirstring=nil)
    path = File.expand_path(folder, dirstring)
    Dir[File.join(path, '**', '*.rb').to_s].each { |f| load(f) }
  end
end; end