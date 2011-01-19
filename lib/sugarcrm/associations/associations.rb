module SugarCRM
  # Holds all the associations for a given class
  class Associations
    # Returns an array of Association objects
    class << self
      def register(owner)
        associations = Associations.new
        owner.link_fields.each_key do |link_field|
          associations << Association.new(owner,link_field)
        end
        associations
      end
    end
    
    attr :associations
    
    def initialize
      @associations = Set.new
      self
    end
    
    # Looks up an association by object, link_field, or method.
    # Raises an exception if not found
    def find!(target)
      @associations.each do |a|
        return a if a.include? target
      end
      raise InvalidAssociation, "Could not lookup association for: #{target}"
    end

    # Looks up an association by object, link_field, or method.
    # Returns false if not found
    def find(association)
      begin
        find!
      rescue InvalidAssociation
        false
      end
    end
    
    def inspect
      self
    end
    
    def to_s
      methods = []
      @associations.each do |a|
        a.methods.each do |m|
          methods << m
        end
      end
      "[#{methods.join(', ')}]"
    end
      
    # delegate undefined methods to the @collection array
    # E.g. contact.cases should behave like an array and allow `length`, `size`, `each`, etc.
    def method_missing(method_name, *args, &block)
      @associations.send(method_name.to_sym, *args, &block)
    end
    
  end
end