module SugarCRM; module AttributeSerializers
  
  protected
    
  # Serializes the id
  def serialize_id
    {:name => "id", :value => id.to_s}
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
  # {:last_name => {:old => "Smit", :new => "Smith"}} 
  # becomes
  # {:last_name => {:name => "last_name", :value => "Smith"}}  
  def serialize_modified_attributes
    attr_hash = {}
    @modified_attributes.each_pair do |name,hash|
      attr_hash[name] = serialize_attribute(name,hash[:new])
    end
    attr_hash[:id] = serialize_id unless new?
    attr_hash
  end
  
  # Un-typecasts the attribute - false becomes "0", 5234 becomes "5234", etc.
  def serialize_attribute(name,value)
    attr_value = value
    attr_type  = attr_type_for(name) 
    case attr_type
    when :bool
      attr_value = 0
      attr_value = 1 if value
    when :datetime, :datetimecombo
      begin
        attr_value = value.strftime("%Y-%m-%d %H:%M:%S")
      rescue
        attr_value = value
      end
    when :int
      attr_value = value.to_s
    end
    {:name => name, :value => attr_value}
  end
end; end
