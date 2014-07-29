module SugarCRM
  # A class for handling SugarCRM Modules
  class Module
    attr_accessor :name, :table_name, :custom_table_name, :klass, :fields, :link_fields
    alias :bean :klass

    # Dynamically register objects based on Module name
    # I.e. a SugarCRM Module named Users will generate
    # a SugarCRM::User class.
    def initialize(session, name)
      @session = session # the session from which this module was retrieved
      @name   = name
      @klass  = name.classify
      unless custom_module?
        table_name = name.tableize
      else
        table_name = @name.downcase
      end
      @table_name = table_name
      # Set table name for custom attibutes
      # Custom attributes are contained in a table named after the module, with a '_cstm' suffix.
      @custom_table_name = table_name + "_cstm"
      @fields = {}
      @link_fields = {}
      @fields_registered = false
      self
    end
    
    # Return true if this module was created in the SugarCRM Studio (i.e. it is not part of the modules that
    # ship in the default SugarCRM configuration)
    def custom_module?
      # custom module names are snake_case (because they have a package key: KEY_tablename),
      # whereas SugarCRM modules are CamelCase
      @name.include? '_'
    end
    
    # Returns the fields associated with the module
    def fields
      return @fields if fields_registered?
      all_fields  = @session.connection.get_fields(@name)
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
      sess = @session
      # class Class < SugarCRM::Base
      #   module_name = "Accounts"
      # end
      klass = Class.new(SugarCRM::Base) do
        self._module = mod_instance
        self.session = sess
      end
      
      # class Account < SugarCRM::Base
      @session.namespace_const.const_set self.klass, klass
      self
    end
    
    # Deregisters the module
    def deregister
      return true unless registered?
      klass = self.klass
      @session.namespace_const.instance_eval{ remove_const klass }
      true
    end

    def registered?
      @session.namespace_const.const_defined? @klass
    end  
      
    def to_s
      @klass
    end
    
    def to_class
      SugarCRM.const_get(@klass).new
    end
      
    class << self
      @initialized = false
      
      # Registers all of the SugarCRM Modules
      def register_all(session)
        namespace = session.namespace_const
        session.connection.get_modules.each do |m|
          session.modules << m.register
        end
        @initialized = true
        true
      end
      
      # Deregisters all of the SugarCRM Modules
      def deregister_all(session)
        namespace = session.namespace_const
        session.modules.each do |m|
          m.deregister
        end
        session.modules = []
        @initialized = false
        true
      end

      # Finds a module by name, or klass name
      def find(name, session=nil)
        session ||= SugarCRM.session
        register_all(session) unless initialized?
        session.modules.each do |m|
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