module SugarCRM; module AssociationCache

  attr_reader :association_cache
    
  # Returns true if an association is cached
  def association_cached?(association)
    @association_cache.symbolize_keys.include? association.to_sym
  end

  # Updates an association cache entry if it's been initialized
  def update_association_cache_for(association, target, action=:add)
    return unless association_cached? association
    case action
    when :add
      return if @association_cache[association].collection.include? target
      @association_cache[association].push(target) # don't use `<<` because overriden method in AssociationCollection gets called instead
    when :delete      
      @association_cache[association].delete target
    end
  end

  # Returns true if an association collection has changed
  def associations_changed?
    @association_cache.values.each do |collection|
      return true if collection.changed?
    end
    false
  end

  protected
  
  # Resets the association cache
  def clear_association_cache
    @association_cache = {}.with_indifferent_access
  end
end; end
