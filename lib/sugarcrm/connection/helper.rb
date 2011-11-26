module SugarCRM; class Connection
  # Attempts to return a list of fields for the target of the association.
  # i.e. if we are associating Contact -> Account, using the "contacts" link
  # field name - this will lookup the contacts association and try to determine
  # the target object type (Contact).  It will then pull the fields for that object
  # and shove them in the related_fields portion of the get_relationship request.
  def resolve_related_fields(module_name, link_field)
    a = Association.new(class_for(module_name), link_field)
    if a.target
      fields = a.target.new.attributes.keys
    else
      fields = ["id"]
    end
    fields.to_json
  end
  
  def resolve_fields(module_name, fields)
    # FIXME: This is to work around a bug in SugarCRM 6.0
    # where no fields are returned if no fields are specified
    if fields.length == 0
      mod = Module.find(module_name.classify, @session)
      if mod
        fields = mod.fields.keys
      else
        fields = ["id"]
      end
    end
    return fields.to_json
  end
  
  # Returns an instance of class for the provided module name
  def class_for(module_name)
    begin
      class_const = @session.namespace_const.const_get(module_name.classify)
      klass = class_const.new
    rescue NameError
      raise InvalidModule, "Module: #{module_name} is not registered"
    end
  end
  
  # We need to strip newlines from Base64 encoding for JSON validation purposes.
  def b64_encode(file)
    Base64.encode64(file).gsub(/\n/, '')
  end
  
  def b64_decode(file)
    Base64.decode64(file)
  end
    
end; end