module SugarCRM; module AttributeMethods

  module ClassMethods
    # Returns a hash of the module fields from the module
    def attributes_from_module_fields
      fields = {}.with_indifferent_access
      self._module.fields.keys.sort.each do |k|
        fields[k.to_s] = nil
      end
      fields
    end
  end
  
  # Determines if attributes have been changed
  def changed?
    @modified_attributes.length > 0
  end
  
  # Is this a new record?
  def new?
    @id.blank?
  end

  # Converts the attributes hash into format recognizable by Sugar
  # { :last_name => "Smith"} 
  # becomes
  # { :last_name => {:name => "last_name", :value => "Smith"}}
  def serialize_attributes
    attr_hash = {}
    @attributes.each_pair do |name,value|
      attr_hash[name] = serialize_attribute(name,value)
    end
    attr_hash[:id] = serialize_id unless new?
    attr_hash
  end

  # Converts the modified_attributes hash into format recognizable by Sugar
  # { :last_name => {:old => "Smit", :new => "Smith"}} 
  # becomes
  # { :last_name => {:name => "last_name", :value => "Smith"}}  
  def serialize_modified_attributes
    attr_hash = {}
    @modified_attributes.each_pair do |name,hash|
      attr_hash[name] = serialize_attribute(name,hash[:new])
    end
    attr_hash[:id] = serialize_id unless new?
    attr_hash
  end

  # Checks to see if we have all the neccessary attributes
  def valid?
    valid = true
    self.class._module.required_fields.each do |attribute|
      case attr_type_for(attribute)
      when "bool"
        case @attributes[attribute]
        when TrueClass:
          next
        when FalseClass:
          next
        else
          @errors.add "#{attribute} must be true or false"
          valid = false
        end
      else 
        if @attributes[attribute].blank?
          @errors.add "#{attribute} cannot be blank"
          valid = false
        end
      end
    end
    valid
  end
  
  # List the required attributes for save
  def required_attributes
    self.class._module.required_fields
  end

  # Serializes the id
  def serialize_id
    {:name => "id", :value => @id.to_s}
  end

  # Un-typecasts the attribute - false becomes 0
  def serialize_attribute(name,value)
    attr_value = value
    case attr_type_for(name)
    when "bool"
      attr_value = 0
      attr_value = 1 if value
    end
    {:name => name, :value => attr_value}
  end

  # Generates get/set methods for keys in the attributes hash
  def define_attribute_methods
    return if attribute_methods_generated?
    @attributes.each_pair do |k,v|
      self.class.module_eval %Q?
      def #{k}
        read_attribute :#{k}
      end
      def #{k}=(value)
        write_attribute :#{k},value
      end
      ?
    end
    self.class.attribute_methods_generated = true
  end

  # Returns an <tt>#inspect</tt>-like string for the value of the
  # attribute +attr_name+. String attributes are elided after 50
  # characters, and Date and Time attributes are returned in the
  # <tt>:db</tt> format. Other attributes return the value of
  # <tt>#inspect</tt> without modification.
  #
  #   person = Person.create!(:name => "David Heinemeier Hansson " * 3)
  #
  #   person.attribute_for_inspect(:name)
  #   # => '"David Heinemeier Hansson David Heinemeier Hansson D..."'
  #
  #   person.attribute_for_inspect(:created_at)
  #   # => '"2009-01-12 04:48:57"'
  def attribute_for_inspect(attr_name)
    value = read_attribute(attr_name)
    if value.is_a?(String) && value.length > 50
      "#{value[0..50]}...".inspect
    elsif value.is_a?(Date) || value.is_a?(Time)
      %("#{value.to_s(:db)}")
    else
      value.inspect
    end
  end

  protected
  
  # Returns the attribute type for a given attribute
  def attr_type_for(attribute)
    field = self.class._module.fields[attribute]
    return false unless field
    field["type"]
  end
  
  # Attempts to typecast each attribute based on the module field type
  def typecast_attributes
    @attributes.each_pair do |name,value|
      attr_type = attr_type_for(name)
      next unless attr_type
      case attr_type
      when "bool"
        @attributes[name] = (value == "1")
      end
    end
    @attributes
  end

  # Wrapper around attributes hash
  def read_attribute(key)
    @attributes[key]
  end
  
  # Wrapper around attributes hash
  def write_attribute(key, value)
    @modified_attributes[key] = { :old => @attributes[key].to_s, :new => value }
    @attributes[key] = value
  end
  
end; end
  