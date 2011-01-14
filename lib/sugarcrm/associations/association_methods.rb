module SugarCRM; module AssociationMethods
  
  module ClassMethods
    # Returns an array of the module link fields
    def associations_from_module_link_fields
      self._module.link_fields.keys
    end
  end
  
  attr :association_cache, false
  
  def association_cached?(association)
    @association_cache.keys.include? association.to_sym
  end
  
  def associations_changed?
    @association_cache.values.each do |collection|
      return true if collection.changed?
    end
    false
  end
  
  protected
  
  def save_modified_associations
    @association_cache.values.each do |collection|
      if collection.changed?
        return false unless collection.save
      end
    end
    true
  end
  
  def clear_association_cache
    @association_cache = {}
  end
  
  # Generates the association proxy methods for related modules
  def define_association_methods
    return if association_methods_generated?
    @associations.each do |k|
      self.class.module_eval %Q?
      def #{k}
        query_association :#{k}
      end
      ?
    end
    self.class.association_methods_generated = true
  end
  
  # Returns the records from the associated module or returns the cached copy if we've already 
  # loaded it.  Force a reload of the records with reload=true
  #
  #  {"email_addresses"=>
  #    {"name"=>"email_addresses",
  #     "module"=>"EmailAddress",
  #     "bean_name"=>"EmailAddress",
  #     "relationship"=>"users_email_addresses",
  #     "type"=>"link"},
  #
  def query_association(assoc, reload=false)
    association = assoc.to_sym
    return @association_cache[association] if association_cached?(association) && !reload
    # TODO: Some relationships aren't fetchable via get_relationship (i.e users.contacts)
    # even though get_module_fields lists them on the related_fields array.  This is most 
    # commonly seen with one-to-many relationships without a join table.  We need to cook 
    # up some elegant way to handle this.
    collection = AssociationCollection.new(self,association,true)
    # add it to the cache
    @association_cache[association] = collection
    collection
  end
  
  # Creates a relationship between the current object and the target
  # The current instance and target records will have a relationship set
  # i.e. account.associate!(contact) wyould link account and contact
  # In contrast to using account.contacts << contact in AssociationCollection, this method doesn't load the relationships
  # before setting the new relationship.
  # This method is useful when certain modules have many links to other modules: not loading the
  # relationships allows one ot avoid a Timeout::Error or a 'stack level too deep' when aprsing JSON
  def associate!(target, target_ids=[], opts={})
    target_ids = [target.id] if target_ids.size < 1
    response = SugarCRM.connection.set_relationship(
      self.class._module.name, self.id, 
      target.class._module.table_name, target_ids,
      opts
    )
    raise AssociationFailed, 
      "Couldn't associate #{@owner.class._module.name}: #{@owner.id} -> #{target.class._module.table_name}:#{target.id}!" if response["failed"] > 0
    true
  end

end; end