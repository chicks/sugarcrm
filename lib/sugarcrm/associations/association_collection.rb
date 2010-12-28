module SugarCRM
  # A class for handling association collections.  Basically just an extension of Array
  class AssociationCollection
    include Enumerable
    
    # creates a new instance of an AssociationCollection
    def initialize(parent, array)
      @parent     = parent
      # we use original to track the state of the collection at start
      @collection = Array.wrap(array).dup
      @original   = Array.wrap(array).freeze
      self
    end
    
    def each(&block)
      @collection.each(&block)
    end
    
    # we should probably delegate this
    def length
      @collection.length
    end
        
    # return any added elements
    def added
      @collection - @original
    end
    
    # return any removed elements
    def removed
      @original - @collection
    end
    
    # Removes an object from the collection, uses the id of the object as a test for inclusion.
    def delete(object)
      raise InvalidRecord, "#{object.class} does not have a valid :id!"
      puts "Attempting to delete #{object._id}"
      @collection.each do |record|
        if record._id == object._id
          puts "Found object to delete"
          @collection.delete(record)
          return true
        end
      end
      false      
    end

    # Checks if a record is included in the current collection.  Uses id's as comparison
    def include?(object)
      @collection.each do |record|
        return true if record._id == object._id
      end
      false
    end
    
    # Add +records+ to this association.  Returns +self+ so method calls may be chained.
    def <<(object)
      result = true
      result = false if include?(object)
      @collection << object
      result && self
    end
    alias :add :<<
    
    def save
      begin
        save!
      rescue
        return false
      end
    end
    
    def save!
      added.each do |record|
        associate!(record)
      end
      removed.each do |record|
        disassociate!(record)
      end
      @original = @collection
      @original.freeze
      true
    end
    
    protected
    
    # Creates a relationship between the current object and the target
    # Parent is the record the Collection is tied to
    # Target is the record we are adding to the collection
    # i.e. user.email_addresses.associate!(EmailAddress.new(:email_address => "abc@abc.com"))
    # user would be the parent, and EmailAddress.new() is the target
    def associate!(target, opts={})
      target.save! if target.new?
      response = SugarCRM.connection.set_relationship(
        @parent.class._module.name, @parent._id, 
        target.class._module.name.downcase, [target._id],
        opts
      )
      raise AssociationFailed, 
        "Couldn't associate #{@parent.class._module.name}: #{@parent._id} -> #{target.class._module.name}:#{target._id}!" if response["failed"] > 0
      true
    end
    
    # Removes a relationship between the current object and the target    
    def disassociate!(target)
      associate!(target,{:delete => 1})
    end

    alias :relate! :associate!
    
  end
end
