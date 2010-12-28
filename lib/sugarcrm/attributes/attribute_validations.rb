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
    if attribute == :system_generated_password
      puts "system_generated_password: #{@attributes[attribute].class} (#{attribute.class}), should be #{attr_type_for(attribute)}"
    end
    case attr_type_for(attribute)
    when :bool
      next if [TrueClass, FalseClass].include? @attributes[attribute]
      @errors.add "#{attribute} must be true or false"
    when :datetime, :datetimecombo
      next if [DateTime].include? @attributes[attribute]  
      @errors.add "#{attribute} must be a DateTime object"      
    when :int
      next if [Fixnum, Float].include? @attributes[attribute]
      @errors.add "#{attribute} must be a Fixnum or Float object"
    else 
      if @attributes[attribute].blank?
        @errors.add "#{attribute} cannot be blank"
      end
    end
  end
end; end