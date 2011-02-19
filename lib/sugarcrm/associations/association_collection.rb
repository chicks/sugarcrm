module SugarCRM
  # A class for handling association collections.  Basically just an extension of Array
  # doesn't actually load the records from Sugar until you invoke one of the public methods
  class AssociationCollection
  
    attr_reader :collection
    
    # creates a new instance of an AssociationCollection
    # Owner is the parent object, and association is the target
    def initialize(owner, association, preload=false)
      @loaded     = false
      @owner      = owner
      @association= association
      load if preload
      self
    end
        
    def changed?
      return false unless loaded?
      return true if added.length > 0
      return true if removed.length > 0
      false
    end
    
    def loaded?
      @loaded
    end
    
    def load
      load_associated_records unless loaded?
    end
    
    def reload
      load_associated_records
    end
     
    # return any added elements
    def added
      load
      @collection - @original
    end
    
    # return any removed elements
    def removed
      load
      @original - @collection
    end
    
    # Removes a record from the collection, uses the id of the record as a test for inclusion.
    def delete(record)
      load
      raise InvalidRecord, "#{record.class} does not have a valid :id!" if record.id.empty?
      @collection.delete record
    end
    alias :remove :delete

    # Checks if a record is included in the current collection.  Uses id's as comparison
    def include?(record)
      load
      @collection.include? record
    end
    
    # Add +records+ to this association, saving any unsaved records before adding them.  
    # Returns +self+ so method calls may be chained.
    # Be sure to call save on the association to commit any association changes
    def <<(record)
      load
      record.save! if record.new?
      result = true
      result = false if include?(record)
      @owner.update_association_cache_for(@association, record, :add)
      record.update_association_cache_for(record.associations.find!(@owner).link_field, @owner, :add)
      result && self
    end
    alias :add :<<
    
    # delegate undefined methods to the @collection array
    # E.g. contact.cases should behave like an array and allow `length`, `size`, `each`, etc.
    def method_missing(method_name, *args, &block)
      load
      @collection.send(method_name.to_sym, *args, &block)
    end
    
    # respond correctly for delegated methods
    def respond_to?(method_name)
      load
      return true if @collection.respond_to? method_name
      super
    end
    
    def save
      begin
        save!
      rescue
        return false
      end
    end
    
    # Pushes collection changes to SugarCRM, and updates the state of the collection
    def save!
      load
      added.each do |record|
        associate!(record)
      end
      removed.each do |record|
        disassociate!(record)
      end
      reload
      true
    end
    
    protected
    
    # Loads related records for the given association
    def load_associated_records
      array = @owner.class.session.connection.get_relationships(@owner.class._module.name, @owner.id, @association.to_s)
      @loaded = true
      # we use original to track the state of the collection at start
      @collection = Array.wrap(array).dup
      @original   = Array.wrap(array).freeze
    end  
    
    # Creates a relationship between the current object and the target
    # Owner is the record the Collection is accessed from
    # Target is the record we are adding to the collection
    # i.e. user.email_addresses.associate!(EmailAddress.new(:email_address => "abc@abc.com"))
    # user would be the owner, and EmailAddress.new() is the target
    def associate!(target, opts={})
      #target.save! if target.new?
      @owner.associate!(target, opts)
    end
    
    # Removes a relationship between the current object and the target    
    def disassociate!(target)
      @owner.associate!(target,{:delete => 1})
    end

    alias :relate! :associate!
    
  end
end
