module SugarCRM
  # Represents an association and it's metadata
  class Association    
    attr :owner
    attr :target
    attr :link_field
    attr :attributes
    attr :methods
    
    def initialize(owner,link_field,opts={})
      @options = { :define_methods? => true }.merge! opts
      @owner = owner
      check_valid_owner
      @link_field = link_field
      @attributes = owner.link_fields[link_field]
      @target = resolve_target
      @methods = define_methods if @options[:define_methods?]
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
    
    protected

    def check_valid_owner
      valid = @owner.class.ancestors.include? SugarCRM::Base
      raise InvalidModule, "#{@owner} is not registered, or is not a descendant of SugarCRM::Base" unless valid
    end
    
    # Attempts to determine the class of the target in the association
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
    
    # Generates the association proxy method for related module
    def define_method(link_field, pretty_name=nil)
      pretty_name ||= link_field
      @owner.class.module_eval %Q?
        def #{pretty_name}
          query_association :#{link_field}
        end
      ?
      pretty_name
    end
    
    # Defines methods for accessing the association target on the owner class.
    # If the link_field name includes the owner class name, it is stripped before 
    # creating the method.  If this occurs, we also create an alias to the stripped
    # method using the full link_field name.
    def define_methods
      methods = []
      pretty_name = humanized_link_name(@link_field)
      methods << define_method(pretty_name)
      if pretty_name != @link_field
        @owner.class.module_eval %Q?
          alias :#{@link_field} #{pretty_name}
        ?
        methods << @link_field
      end
      methods
    end
    
    # Return the name of the relationship excluding the owner part of the name.
    # e.g. if a custom relationship is defined in Studio between Tasks and Documents,
    # the link_field will be `tasks_documents` but a human would call the relationship `documents`
    def humanized_link_name(link_field)
      # Split the relationship name into parts
      # "contact_accounts" => ["contact","accounts"]
      m = link_field.split(/_/)
      # Determine the parts we don't want
      # SugarCRM::Contact => ["contacts", "contact"]
      o = @owner.class._module.table_name
      # Use array subtraction to remove parts representing the owner side of the relationship
      # ["contact", "accounts"] - ["contacts", "contact"] => ["accounts"]
      t = m - [o, o.singularize]
      # Reassemble whatever's left
      # "accounts"
      t.join('_')
    end
    
  end
end

