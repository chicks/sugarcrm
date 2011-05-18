module SugarCRM; module AttributeValidations
  # Checks to see if we have all the neccessary attributes
  def valid?
    @errors = (defined?(HashWithIndifferentAccess) ? HashWithIndifferentAccess : ActiveSupport::HashWithIndifferentAccess).new
    
    self.class._module.required_fields.each do |attribute|
      valid_attribute?(attribute)
    end
    
    # for rails compatibility
    def @errors.full_messages
      # After removing attributes without errors, flatten the error hash, repeating the name of the attribute before each message:
      # e.g. {'name' => ['cannot be blank', 'is too long'], 'website' => ['is not valid']}
      # will become 'name cannot be blank, name is too long, website is not valid
      self.inject([]){|memo, obj| memo.concat(obj[1].inject([]){|m, o| m << "#{obj[0].to_s.humanize} #{o}" })}
    end
    
    # Rails needs each attribute to be present in the error hash (if the attribute has no error, it has [] as a value)
    # Redefine the [] method for the errors hash to return [] instead of nil is the hash doesn't contain the key
    class << @errors
      alias :old_key_lookup :[]
      def [](key)
        old_key_lookup(key) || Array.new
      end
    end
    
    @errors.size == 0
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
        add_error(attribute, "cannot be blank")
      end
    end
  end
  
  # Compares the class of the attribute with the class or classes provided in the class array
  # returns true if they match, otherwise adds an entry to the @errors collection, and returns false
  def validate_class_for(attribute, class_array)
    return true if class_array.include? @attributes[attribute].class
    add_error(attribute, "must be a #{class_array.join(" or ")} object (not #{@attributes[attribute].class})")
    false  
  end
  
  # Add an error to the hash
  def add_error(attribute, message)
    @errors[attribute] ||= []
    @errors[attribute] = @errors[attribute] << message unless @errors[attribute].include? message
    @errors
  end
end; end
