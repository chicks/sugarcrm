module SugarCRM; class Connection
  def resolve_fields(module_name, fields)
    # FIXME: This is to work around a bug in SugarCRM 6.0
    # where no fields are returned if no fields are specified
    if fields.length == 0
      return Module.find(module_name).fields.keys.to_json
    else 
      return fields.to_json
    end
  end
end; end