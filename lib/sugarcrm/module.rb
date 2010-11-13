module SugarCRM
  # A class for handling SugarCRM Modules
  class Module
    attr :name, false
    attr :klass, false
    attr :fields, false
    attr :link_fields, false

    # Dynamically register objects based on Module name
    # I.e. a SugarCRM Module named Users will generate
    # a SugarCRM::User class.
    def initialize(name)
      @name   = name
      @klass  = name.classify
      @fields = {}
      @link_fields  = {}
      @fields_registered = false
      self
    end
    
    def fields
      return @fields if fields?
      all_fields  = SugarCRM.connection.get_fields(@name)
      @fields     = all_fields["module_fields"]
      @link_fields= all_fields["link_fields"] 
      @fields_registered = true
      @fields
    end
    
    def fields?
      @fields_registered
    end
    
    def link_fields
      self.fields unless link_fields?
      handle_empty_array
      @link_fields
    end
    
    def link_fields?
      @fields_registered
    end  
  
    def handle_empty_array
      if @link_fields.class == Array && @link_fields.length == 0
        @link_fields = {}
      end
    end
    
    # Registers a single module by name
    # Adds module to SugarCRM.modules (SugarCRM.modules << Module.new("Users"))
    # Adds module class to SugarCRM parent module (SugarCRM.constants << User)
    # Note, SugarCRM::User.module == Module.find("Users")
    def register
      return self if registered?
      mod_instance = self
      # class Class < SugarCRM::Base
      #   module_name = "Accounts"
      # end
      klass = Class.new(SugarCRM::Base) do
        self._module = mod_instance
      end 
      
      # class Account < SugarCRM::Base
      SugarCRM.const_set self.klass, klass
      self
    end

    def registered?
      SugarCRM.const_defined? @klass
    end  
      
    def to_s
      @name
    end
    
    def to_class
      SugarCRM.const_get(@klass).new
    end
      
    class << self
      @initialized = false
      
      # Registers all of the SugarCRM Modules
      def register_all
        SugarCRM.connection.get_modules.each do |m|
          SugarCRM.modules << m.register
        end
        @initialized = true
        true
      end

      # Finds a module by name, or klass name
      def find(name)
        register_all unless initialized?
        SugarCRM.modules.each do |m|
          return m if m.name  == name
          return m if m.klass == name
        end
        false
      end
      
      # Class variable to track if we've initialized or not
      def initialized?
        @initialized ||= false
      end
      
    end
  end
end