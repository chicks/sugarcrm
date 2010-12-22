module SugarCRM; module AttributeTypeCast

  protected
  
  # Returns the attribute type for a given attribute
  def attr_type_for(attribute)
    field = self.class._module.fields[attribute]
    #puts "Looking up type for: #{attribute} Got: #{field["type"]}"
    return false unless field.is_a? Hash
    field["type"].to_sym
  end

  # Attempts to typecast each attribute based on the module field type
  def typecast_attributes
    @attributes.each_pair do |name,value|
      # skip primary key columns
      next if name == "id"
      attr_type = attr_type_for(name)
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