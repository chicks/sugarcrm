module SugarCRM; module AssociationCache

  attr :association_cache, false
  

  
  # Returns true if an association is cached
  def association_cached?(association)
    @association_cache.keys.include? association
  end

  protected

  # Returns true if an association collection has changed
  def associations_changed?
    @association_cache.values.each do |collection|
      return true if collection.changed?
    end
    false
  end

  def save_modified_associations
    @association_cache.values.each do |collection|
      if collection.changed?
        return false unless collection.save
      end
    end
    true
  end
  
  # Updates an association cache entry if it's been initialized
  def update_association_cache_for(association, target)
    # only add to the cache if the relationship has been queried
    @association_cache[association] << target if association_cached? association
  end
  
  # Resets the association cache
  def clear_association_cache
    @association_cache = {}.with_indifferent_access
  end
end; end
