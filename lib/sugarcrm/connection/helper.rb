module SugarCRM; class Connection
  def resolve_fields(module_name, fields)
    # FIXME: This is to work around a bug in SugarCRM 6.0
    # where no fields are returned if no fields are specified
    if fields.length == 0
      mod = Module.find(module_name)
      if mod
        fields = mod.fields.keys
      else  
        fields = "id"
      end
    end
    return fields.to_json
  end
end; end