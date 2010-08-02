module SugarCRM
  class Base
 
    # Runs a find against the remote service
    def self.find(id)
      response = connection.get_entry(self.module_name, id,{:fields => self.module_fields.keys})
      response.object
    end

  end
end