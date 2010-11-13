module SugarCRM
  # A class for handling SugarCRM Modules
  class Module
    attr :name, false
    attr :klass, false
    attr :fields, false

    # Dynamically register objects based on Module name
    # I.e. a SugarCRM Module named Users will generate
    # a SugarCRM::User class.
    def initialize(name)
      @name   = name
      @klass  = name.classify
      @fields = {}
      @fields_registered = false
      self
    end
    
    def fields
      return @fields if fields?
      @fields = SugarCRM.connection.get_fields(@name)
      @fields_registered = true
      @fields.keys
    end
    
    def fields?
      @fields_registered
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