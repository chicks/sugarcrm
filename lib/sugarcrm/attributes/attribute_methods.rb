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
    
  # Returns the primary_key
  # TODO: Write a test to assert ID's are handled properly
  def _id
    @id
  end
    
  alias :id :_id
  alias :pk :_id
  alias :primary_key :_id
  
  # Determines if attributes have been changed
  def changed?
    @modified_attributes.length > 0
  end
  
  # Is this a new record?
  def new?
    @id.blank?
  end
  
  # List the required attributes for save
  def required_attributes
    self.class._module.required_fields
  end

  protected
  
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
  
  # Wrapper for invoking save on modified_attributes
  # sets the id if it's a new record
  def save_modified_attributes
    raise InvalidRecord, @errors.to_a.join(", ") if !valid?
    # If we get a Hash back, return true.  Otherwise return false.
    response = SugarCRM.connection.set_entry(self.class._module.name, serialize_modified_attributes)
    if response.is_a? Hash
      pp 
      @id = response["id"] if new?
    else
      return false
    end
    # TODO: Write a test to confirm save and save! work properly
    @modified_attributes = {}
    true
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
  