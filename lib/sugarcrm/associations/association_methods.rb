module SugarCRM; module AssociationMethods

  module ClassMethods
  end

  # Saves all modified associations.
  def save_modified_associations!
    @association_cache.values.each do |collection|
      if collection.changed?
        collection.save!
      end
    end
    true
  end
  
  # Returns the module link fields hash
  def link_fields
    self.class._module.link_fields
  end
  
  # Creates a relationship between the current object and the target object
  # The current and target records will have a relationship set
  # i.e. account.associate!(contact) would link account and contact
  # In contrast to using account.contacts << contact, this method doesn't load the relationships
  # before setting the new relationship.
  # This method is useful when certain modules have many links to other modules: not loading the
  # relationships allows one ot avoid a Timeout::Error
  def associate!(target,opts={})
    targets = Array.wrap(target)
    targets.each do |t|
      association = @associations.find!(t)
      response = SugarCRM.connection.set_relationship(
        self.class._module.name, self.id, 
        association.link_field, [t.id], opts
      )
      if response["failed"] > 0
        raise AssociationFailed, 
        "Couldn't associate #{self.class._module.name}: #{self.id} -> #{t}: #{t.id}!" 
      end
      update_association_cache_for(association.link_field, t)
    end
    true
  end
    
  protected

  # Generates the association proxy methods for related modules
  def define_association_methods
    @associations = Associations.register(self)
    return if association_methods_generated?
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

end; end