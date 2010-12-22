module SugarCRM; module AssociationMethods
  
  module ClassMethods
    # Returns an array of the module link fields
    def associations_from_module_link_fields
      self._module.link_fields.keys
    end
  end
  
  protected
  
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
  
  def associations_modified?
    @modified_associations.length > 0
  end
  
  # Saves any modified associations
  def save_modified_associations
    return true unless associations_modified?
    @modified_associations.keys.each do |collection|
      collection.save!
    end
  end
  
  # Loads related records for the given association
  def load_associations_for(association)
    SugarCRM.connection.get_relationships(self.class._module.name, self._id, association.to_s)
  end
  
  #
  #  {"email_addresses"=>
  #    {"name"=>"email_addresses",
  #     "module"=>"EmailAddress",
  #     "bean_name"=>"EmailAddress",
  #     "relationship"=>"users_email_addresses",
  #     "type"=>"link"},
  #
  # Returns the records from the associated module or returns the cached copy if we've already 
  # loaded it.  Force a reload of the records with reload=true
  def query_association(association, reload=false)
    return @association_cache[association] if association_cached?(association) && !reload
    # TODO: Some relationships aren't fetchable via get_relationship (i.e users.contacts)
    # even though get_module_fields lists them on the related_fields array.  This is most 
    # commonly seen with one-to-many relationships without a join table.  We need to cook 
    # up some elegant way to handle this.
    collection = AssociationCollection.new(
      self,
      load_associations_for(association)
    )
    # add it to the cache
    @association_cache[association] = collection
    collection
  end
  
  # TODO: Do we even need this?
  def update_association(association, value)
    false
  end
  
  def association_cached?(association)
    @association_cache.keys.include? association
  end
  
end; end