module SugarCRM
  
  @@connection = nil
  def self.connection
    @@connection
  end
  def self.connection=(connection)
    @@connection = connection
  end
  
  @@modules = []
  def self.modules
    @@modules
  end
  def self.modules=(modules)
    @@modules = modules
  end
end