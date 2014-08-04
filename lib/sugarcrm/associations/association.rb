module SugarCRM
  
  # Associations are middlemen between the object that holds the association, known as the @owner, 
  # and the actual associated object, known as the @target.  Methods are added to the @owner that 
  # allow access to the association collection, and are held in @proxy_methods.  The cardinality 
  # of the association is available in @cardinality, and the actual relationship details are held
  # in @relationship.
  class Association
    attr_accessor :owner, :target, :link_field, :relationship, :attributes, :proxy_methods, :cardinality
    
    # Creates a new instance of an Association
    def initialize(owner,link_field,opts={})
      @options = { :define_methods? => true }.merge! opts
      @owner = owner
      check_valid_owner
      @link_field = link_field
      @attributes = owner.link_fields[link_field]
      @relationship = relationship_for(@attributes["relationship"])
      @target = resolve_target
      @proxy_methods = define_methods if @options[:define_methods?]
      @cardinality = resolve_cardinality
      self
    end
    
    # Returns true if the association includes an attribute that matches
    # the provided string
    def include?(attribute)
      return true if attribute.class == @target
      return true if attribute == link_field
      return true if methods.include? attribute
      false
    end
    
    def ==(comparison_object)
      comparison_object.instance_of?(self.class) &&
      @target.class == comparison_object.class &&
      @link_field == comparison_object.link_field
    end
    alias :eql? :==
        
    def hash
      "#{@target.class}##{@link_field}".hash
    end
    
    def inspect
      self
    end
    
    def to_s
      "#<#{@owner.class.session.namespace_const}::Association @proxy_methods=[#{@proxy_methods.join(", ")}], " +
      "@link_field=\"#{@link_field}\", @target=#{@target}, @owner=#{@owner.class}, " +
      "@cardinality=:#{@cardinality}>"
    end
    
    def pretty_print(pp)
      pp.text self.inspect, 0
    end
    
    protected

    def check_valid_owner
      valid = @owner.class.ancestors.include? SugarCRM::Base
      raise InvalidModule, "#{@owner} is not registered, or is not a descendant of SugarCRM::Base" unless valid
    end
    
    # Attempts to determine the class of the target in the association
    def resolve_target
      # Use the link_field name first
      klass = @link_field.singularize.camelize
      namespace = @owner.class.session.namespace_const
      return namespace.const_get(klass) if namespace.const_defined? klass
      # Use the link_field attribute "module"
      if @attributes["module"].length > 0
        module_name = SugarCRM::Module.find(@attributes["module"], @owner.class.session)
        return namespace.const_get(module_name.klass) if module_name && namespace.const_defined?(module_name.klass)
      end
      # Use the "relationship" target
      if @attributes["relationship"].length > 0
        klass = @relationship[:target][:name].singularize.camelize
        return namespace.const_get(klass) if namespace.const_defined? klass
      end
      false
    end
    
    # Defines methods for accessing the association target on the owner class.
    # If the link_field name includes the owner class name, it is stripped before 
    # creating the method.  If this occurs, we also create an alias to the stripped
    # method using the full link_field name.
    def define_methods
      methods = []
      pretty_name = @relationship[:target][:name]
      methods << define_method(@link_field)
      methods << define_alias(pretty_name, @link_field) if pretty_name != @link_field
      methods
    end
    
    # Generates the association proxy method for related module
    def define_method(link_field)
      raise ArgumentError, "argument cannot be nil" if link_field.nil?
      if (@owner.respond_to? link_field.to_sym) && @owner.debug
        warn "Warning: Overriding method: #{@owner.class}##{link_field}"
      end
      @owner.class.module_eval %Q?
        def #{link_field}
          query_association :#{link_field}
        end
      ?
      link_field
    end
    
    # Defines a method alias.  Checks to see if a method is already defined.
    def define_alias(alias_name, method_name)
      @owner.class.module_eval %Q?
        alias :#{alias_name} :#{method_name}
      ?
      alias_name
    end
    
    # This method breaks the relationship into parts and returns them
    def relationship_for(relationship)
      # We need to run both regexes, because the plurality of the @owner module name is 
      # important
      plural_regex   = /((.*)_)?(#{Regexp.quote(@owner.class._module.name.downcase)})(_(.*))?/
      singular_regex = /((.*)_)?(#{Regexp.quote(@owner.class._module.name.downcase.singularize)})(_(.*))?/
      # Break the loop if we match
      [plural_regex, singular_regex].each {|r| break if relationship.match(r)}
      # Assign sane values to things if we didnt match
      o   = $3
      o   = @owner.class._module.name.downcase if o.nil? || o.empty?
      t   = [$2, $5].compact.join('_')
      t   = @link_field if t.nil? || t.empty?
      # Look up the cardinality
      o_c, t_c = cardinality_for(o,t)
      {:owner   => {:name => o, :cardinality => o_c},
       :target  => {:name => t, :cardinality => t_c}}
    end
    
    # Determines if the provided string is plural or singular
    # Plurality == Cardinality
    def cardinality_for(*args)
      args.inject([]) {|results,arg|
        result = :many 
        result = :one if arg.singularize == arg
        results << result        
      }
    end
    
    def resolve_cardinality
      "#{@relationship[:owner][:cardinality]}_to_#{@relationship[:target][:cardinality]}".to_sym
    end
  end
end

