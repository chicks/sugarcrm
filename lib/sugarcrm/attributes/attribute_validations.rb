module SugarCRM; module AttributeValidations
  # Checks to see if we have all the neccessary attributes
  def valid?
    @errors = Set.new
    self.class._module.required_fields.each do |attribute|
      valid_attribute?(attribute)
    end
    @errors.length == 0
  end
  
  protected
  
  # TODO: Add test cases for validations
  def valid_attribute?(attribute)
    case attr_type_for(attribute)
    when :bool
      validate_class_for(attribute, [TrueClass, FalseClass])
    when :datetime, :datetimecombo
      validate_class_for(attribute, [DateTime])
    when :int
      validate_class_for(attribute, [Fixnum, Float])
    else 
      if @attributes[attribute].blank?
        @errors.add "#{attribute} cannot be blank"
      end
    end
  end
  
  # Compares the class of the attribute with the class or classes provided in the class array
  # returns true if they match, otherwise adds an entry to the @errors collection, and returns false
  def validate_class_for(attribute, class_array)
    return true if class_array.include? @attributes[attribute].class
    @errors.add "#{attribute} must be a #{class_array.join(" or ")} object (not #{@attributes[attribute].class})"
    false  
  end
  
end; end