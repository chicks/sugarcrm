module SugarCRM; module AssociationMethods
  
  # Returns an array of the module link fields
  def associations_from_module_link_fields
    self.class._module.link_fields.keys
  end
  
  # Generates the association proxy methods for related modules
  def define_association_methods
    return if association_methods_generated?
    @associations.each do |k|
      self.class.module_eval %Q?
      def #{k}
        query_association :#{k}
      end
      def #{k}=(value)
        update_association :#{k},value
      end
      ?
    end
    self.class.association_methods_generated = true
  end
  
  #
  #  {"email_addresses"=>
  #    {"name"=>"email_addresses",
  #     "module"=>"EmailAddress",
  #     "bean_name"=>"EmailAddress",
  #     "relationship"=>"users_email_addresses",
  #     "type"=>"link"},
  #
  def query_association(association)
    klass = self.class._module.link_fields[association.to_s]["module"]
    klass = self.class._module.link_fields[association.to_s].classify unless klass
    objects = SugarCRM.connection.get_relationships(
      self.class._module.name,
      self.id,
      association.to_s
    )
  end
  
  def update_association(association, value)
    false
  end
  
end; end