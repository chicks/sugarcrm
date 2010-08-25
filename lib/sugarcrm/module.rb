module SugarCRM
  class Base
 
    # Runs a find against the remote service
    def self.find(id)
      response = connection.get_entry(self.module_name, id,{:fields => self.module_fields.keys})
      response.to_obj
    end
    
    def save
      response = connection.set_entry(self.module_name, @attributes)
    end

  end
end