module SugarCRM; module AttributeTypeCast

  protected
  
  # Returns the attribute type for a given attribute
  def attr_type_for(attribute)
    fields = self.class._module.fields
    field  = fields[attribute]
    raise UninitializedModule, "#{self.class.session.namespace_const}Module #{self.class._module.name} was not initialized properly (fields.length == 0)" if fields.length == 0
    raise InvalidAttribute, "#{self.class}._module.fields does not contain an entry for #{attribute} (of type: #{attribute.class})\nValid fields: #{self.class._module.fields.keys.sort.join(", ")}" if field.nil?
    raise InvalidAttributeType, "#{self.class}._module.fields[#{attribute}] does not have a key for \'type\'" if field["type"].nil?
    field["type"].to_sym
  end

  # Attempts to typecast each attribute based on the module field type
  def typecast_attributes
    @attributes.each_pair do |name,value|
      # skip primary key columns
      # ajay Singh --> skip the loop if attribute is null (!name.present?)
      next if (name == "id") or (!name.present?)
      attr_type = attr_type_for(name)
      
      # empty attributes should stay empty (e.g. an empty int field shouldn't be typecast as 0)
      if [:datetime, :datetimecombo, :int].include? attr_type && (value.nil? || value == '')
        @attributes[name] = nil
        next
      end
      
      case attr_type
      when :bool
        @attributes[name] = (value == "1")
      when :datetime, :datetimecombo
        begin
          @attributes[name] = DateTime.parse(value)
        rescue
          @attributes[name] = value
        end
      when :int
        @attributes[name] = value.to_i
      end
    end
    @attributes
  end

end; end