require 'sugarcrm/attribute_methods'
require 'sugarcrm/association_methods'

module SugarCRM; class Base 

  # Unset all of the instance methods we don't need.
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$|^define_method$|^class$|^instance_of.$)/ }

  # This holds our connection
  cattr_accessor :connection, :instance_writer => false
    
  # Tracks if we have extended our class with attribute methods yet.
  class_attribute :attribute_methods_generated
  self.attribute_methods_generated = false
  
  class_attribute :association_methods_generated
  self.association_methods_generated = false
  
  class_attribute :_module
  self._module = nil
  
  # Contains a list of attributes
  attr :attributes, true
  attr :id, true
  attr :debug, true

  class << self # Class methods
    def establish_connection(url, user, pass, opts={})
      options = { 
        :debug  => false,
      }.merge(opts)
      @debug  = options[:debug]
      @@connection = SugarCRM::Connection.new(url, user, pass, @debug)
    end
  
    # Runs a find against the remote service
    def find(id)
      response = SugarCRM.connection.get_entry(self._module.name, id, {:fields => self._module.fields.keys})
    end
  end

  # Creates an instance of a Module Class, i.e. Account, User, Contact, etc.
  # This call depends upon SugarCRM.modules having actual data in it.  If you 
  # are using Base.establish_connection, you should be fine.  But if you are 
  # using the Connection class by itself, you may need to prime the pump with
  # a call to Module.register_all
  def initialize(id=nil, attributes={})
    @id = id
    @attributes = attributes_from_module_fields.merge(attributes)
    @associations = associations_from_module_link_fields
    define_attribute_methods
    define_association_methods
  end

  def inspect
    self
  end
  
  def to_s
    attrs = []
    @attributes.each_key do |k|
       attrs << "#{k}: #{attribute_for_inspect(k)}"
    end
    "#<#{self.class} #{attrs.join(", ")}>"
  end

  def save
    response = SugarCRM.connection.set_entry(self._module.name, @attributes)
  end
  
  # Wrapper around class attribute
  def attribute_methods_generated?
    self.class.attribute_methods_generated
  end  
  
  def association_methods_generated?
    self.class.association_methods_generated
  end

  Base.class_eval do
    include AttributeMethods
    include AssociationMethods
  end

end; end 