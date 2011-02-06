module SugarCRM
  # Represents an association and it's metadata
  class Association    
    attr :owner, true
    attr :target, true
    attr :link_field, true
    attr :attributes, true 
    attr :proxy_methods, true 
    
    # TODO: Describe this.
    def initialize(owner,link_field,opts={})
      @options = { :define_methods? => true }.merge! opts
      @owner = owner
      check_valid_owner
      @link_field = link_field
      @attributes = owner.link_fields[link_field]
      @target = resolve_target
      @proxy_methods = define_methods if @options[:define_methods?]
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
      "#<SugarCRM::Association @proxy_methods=[#{@proxy_methods.join(", ")}], @link_field=\"#{@link_field}\", @target=#{@target}, @owner=#{@owner.class}>"
    end
    
    protected

    def check_valid_owner
      valid = @owner.class.ancestors.include? SugarCRM::Base
      raise InvalidModule, "#{@owner} is not registered, or is not a descendant of SugarCRM::Base" unless valid
    end
    
    # Attempts to determine the class of the target in the association
    # TODO: Write tests for this.
    def resolve_target
      # Use the link_field name first
      klass = @link_field.singularize.camelize
      return "SugarCRM::#{klass}".constantize if SugarCRM.const_defined? klass
      # Use the link_field attribute "module"
      if @attributes["module"].length > 0
        module_name = SugarCRM::Module.find(@attributes["module"])
        return "SugarCRM::#{module_name.klass}".constantize if SugarCRM.const_defined? module_name.klass
      end
      # Use the link_field attribute "relationship"
      if @attributes["relationship"].length > 0
        klass = humanized_link_name(@attributes["relationship"]).singularize.camelize
        return "SugarCRM::#{klass}".constantize if SugarCRM.const_defined? klass
      end
      false
    end
    
    # Defines methods for accessing the association target on the owner class.
    # If the link_field name includes the owner class name, it is stripped before 
    # creating the method.  If this occurs, we also create an alias to the stripped
    # method using the full link_field name.
    def define_methods
      methods = []
      pretty_name = humanized_link_name(@link_field)
      methods << define_method(@link_field)
      if pretty_name != @link_field
        @owner.class.module_eval %Q?
          alias :#{pretty_name} #{@link_field}
        ?
        methods << @link_field
      end
      methods
    end
    
    # Generates the association proxy method for related module
    def define_method(link_field)
      @owner.class.module_eval %Q?
        def #{link_field}
          query_association :#{link_field}
        end
      ?
      link_field
    end
    
    # Return the name of the relationship excluding the owner part of the name.
    # e.g. if a custom relationship is defined in Studio between Tasks and Documents,
    # the link_field will be `tasks_documents` but a human would call the relationship `documents`
    def humanized_link_name(link_field)
      # the module name is used to function properly with modules containing '_' (e.g. a custom module abc_sale : custom modules need a prefix (abc here) so they will always have a '_' in their table name)
      return link_field unless link_field.to_s =~ /((.*)_)?#{Regexp.quote(@owner.class._module.name.downcase)}(_(.*))?/
      [$2, $4].compact.join('_')
    end
  end
end

