module SugarCRM; module AttributeMethods

  module ClassMethods
    # Returns a hash of the module fields from the module
    def attributes_from_module
      fields = {}.with_indifferent_access
      self._module.fields.keys.sort.each do |k|
        fields[k] = nil
      end
      fields
    end
    # Returns the table name for a given attribute
    def table_name_for(attribute)
      table_name = self._module.table_name
      if attribute.to_s =~ /_c$/
        table_name = self._module.custom_table_name
      end
      table_name
    end
    # Takes a condition like: [:zip, ["> 75000", "< 80000"]]
    # and flattens it to: ["accounts.zip > 75000", "accounts.zip < 80000"]
    def flatten_conditions_for(condition)
      conditions = []
      attribute, attribute_conditions = condition
      # Make sure we wrap the attribute condition in an array for EZ handling...
      Array.wrap(attribute_conditions).each do |attribute_condition| 
        # parse operator in cases where: 
        #   :attribute => '>= some_value', 
        #   :attribute => "LIKE '%value%'", 
        # fallback to '=' operator as default]
        operator = attribute_condition.to_s[/^([!<>=]*(LIKE|IS|NOT|\s)*)(.*)$/,1].strip!
        # Default to = if we can't resolve the condition.
        operator ||= '=' 
        # Extract value from query
        value = $3
        unless attribute_condition.class == FalseClass
          if attribute_condition.class == TrueClass
            # fix value for checkboxes: users can pass true as condition, should be converted to '1' (false case for checkboxes is treated separately below)
            value = (attribute_condition.class == TrueClass ? '1' : '0')
          end
          
          # TODO: Write a test for sending invalid attribute names.  
          # strip single quotes
          value = value.strip[/'?([^']*)'?/,1] 
          conditions << "#{table_name_for(attribute)}.#{attribute} #{operator} \'#{value}\'"
        else
          # When a user creates a custom checkbox field, a column is added to the *_cstm table for that module (e.g. contacts_cstm for Contacts module).
          # Each time a new record is created, the value of the checkbox will be stored in that _cstm table.
          # However, records that exsited before that field was created are absent from the _cstm table.
          # To return the expected results when a user is searching for records with an unchecked checkbox, we must return all records that aren't present in
          # the _cstm table with a value of 1 (returning the record with 0 in the table will ignore the pre-existing records).
          # Here, we create the appropriate query that will return all records that don't have a value of "true" in the checkbox field.
          conditions << "#{self._module.table_name}.id NOT IN (SELECT id_c FROM #{table_name_for(attribute)} WHERE #{table_name_for(attribute)}.#{attribute} #{operator} 1)"
        end
      end
      conditions
    end
  end
    
  # Determines if attributes or associations have been changed
  def changed?
    return true if attributes_changed?
    return true if associations_changed?
    false
  end
  
  def destroyed?
    @attributes[:deleted]
  end
  
  def attributes_changed?
    @modified_attributes.length > 0
  end
  
  # Is this a new record?
  def new?
    @attributes[:id].blank?
  end
  alias :new_record? :new?
  
  # List the required attributes for save
  def required_attributes
    self.class._module.required_fields
  end
  alias :required_fields :required_attributes
  
  def to_model
    self
  end

  protected
  
  # Merges attributes provided as an argument to initialize
  # with attributes from the module.fields array.  Skips any
  # fields that aren't in the module.fields array
  #
  # BUG: SugarCRM likes to return fields you don't ask for and
  # aren't fields on a module (i.e. modified_user_name).  This 
  # royally screws up our typecasting code, so we handle it here.
  def merge_attributes(attrs={})
    # copy attributes from the parent module fields array
    @attributes = self.class.attributes_from_module
    # populate the attributes with values from the attrs provided to init.
    @attributes.keys.each do |name|
      write_attribute name, attrs[name] if attrs[name]
    end
    # If this is an existing record, blank out the modified_attributes hash
    @modified_attributes = {} unless new?
  end
  
  # Generates get/set methods for keys in the attributes hash
  def define_attribute_methods
    return if attribute_methods_generated?
    @attributes.keys.sort.each do |k|
      # ajay Singh --> skip the loop if attribute is null
      next if !k.present?
      self.class.module_eval %Q?
        def #{k}
          read_attribute :#{k}
        end
        def #{k}=(value)
          write_attribute :#{k},value
        end
        def #{k}\?
          has_attribute\? :#{k}
        end
      ?
    end
    
    # return the (polymorphic) parent record corresponding to the parent_id and parent_type attributes
    # (an example of parent polymorphism can be found in the Note module)
    if (@attributes.keys.include? 'parent_id') && (@attributes.keys.include? 'parent_type')
      self.class.module_eval %Q?
      def parent
        (self.class.session.namespace_const.const_get @attributes['parent_type'].singularize).find(@attributes['parent_id'])
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
  def save_modified_attributes!(opts={})
    options = { :validate => true }.merge(opts)
    if options[:validate]
      # Complain if we aren't valid
      raise InvalidRecord, @errors.full_messages.join(", ") unless valid?
    end
    # Send the save request
    response = self.class.session.connection.set_entry(self.class._module.name, serialize_modified_attributes)
    # Complain if we don't get a parseable response back
    raise RecordsaveFailed, "Failed to save record: #{self}.  Response was not a Hash" unless response.is_a? Hash
    # Complain if we don't get a valid id back
    raise RecordSaveFailed, "Failed to save record: #{self}.  Response did not contain a valid 'id'." if response["id"].nil?
    # Save the id to the record, if it's a new record
    @attributes[:id] = response["id"] if new?
    raise InvalidRecord, "Failed to update id for: #{self}." if id.nil?
    # Clear the modified attributes Hash
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
  
  def has_attribute?(key)
    @attributes.has_key? key
  end
  
end; end
  