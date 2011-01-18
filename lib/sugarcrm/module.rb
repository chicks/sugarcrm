module SugarCRM
  # A class for handling SugarCRM Modules
  class Module
    attr :name, true
    attr :table_name, true
    attr :custom_table_name, true
    attr :klass, true
    attr :fields, true
    attr :link_fields, true
    alias :bean :klass

    # Dynamically register objects based on Module name
    # I.e. a SugarCRM Module named Users will generate
    # a SugarCRM::User class.
    def initialize(name)
      @name   = name
      @klass  = name.classify
      @table_name = name.tableize
      @custom_table_name = resolve_custom_table_name      
      @fields = {}
      @link_fields = {}
      @fields_registered = false
      self
    end
    
    # Return true if this module was created in the SugarCRM Studio (i.e. it is not part of the modules that
    # ship in the default SugarCRM configuration)
    def custom_module?
      # custom module names are all lower_case, whereas SugarCRM modules are CamelCase
      @name.downcase == @name 
    end

    # Set table name for custom attibutes
    # Custom attributes are contained in a table named after the module, with a '_cstm' suffix.
    # The module's table name must be tableized for the modules that ship with SugarCRM.
    # For custom modules (created in the Studio), table name don't need to be tableized since
    # the name passed to the constructor is already tableized    
    def resolve_custom_table_name
      @custom_table_name = @table_name + "_cstm"
      @custom_table_name = @name + "_cstm" if custom_module?
    end
    
    # Returns the fields associated with the module
    def fields
      return @fields if fields_registered?
      all_fields  = SugarCRM.connection.get_fields(@name)
      @fields     = all_fields["module_fields"].with_indifferent_access
      @link_fields= all_fields["link_fields"]
      handle_empty_arrays
      @fields_registered = true
      @fields
    end
    
    def fields_registered?
      @fields_registered
    end
    
    alias :link_fields_registered? :fields_registered?
    
    # Returns the required fields
    def required_fields
      required_fields = []
      ignore_fields = [:id, :date_entered, :date_modified]
      self.fields.each_value do |field|
        next if ignore_fields.include? field["name"].to_sym
        required_fields << field["name"].to_sym if field["required"] == 1
      end 
      required_fields
    end
    
    def link_fields
      self.fields unless link_fields_registered?
      handle_empty_arrays
      @link_fields
    end
    
    # TODO: Refactor this to be less repetitive
    def handle_empty_arrays
      @fields = {}.with_indifferent_access if @fields.length == 0
      @link_fields = {}.with_indifferent_access if @link_fields.length == 0
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