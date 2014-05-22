module SugarCRM; class Response
  class << self
    # This class handles the response from the server.
    # It tries to convert the response into an object such as User
    # or an object collection.  If it fails, it just returns the response hash
    def handle(json, session)
      r = new(json, session)
      begin
        return r.to_obj
      rescue UninitializedModule => e
        raise e
      rescue InvalidAttribute => e
        raise e
      rescue InvalidAttributeType => e
        raise e
      rescue => e
        if session.connection.debug?
          puts "Failed to process JSON:"
          pp json
        end
        raise e
      end
    end
  end

  attr_reader :response
  
  def initialize(json, session, opts={})
    @options  = { :always_return_array => false }.merge! opts
    @response = json
    @response = json.with_indifferent_access if json.is_a? Hash
    @session = session
  end
  
  # Tries to instantiate and return an object with the values
  # populated from the response
  def to_obj
    # If this is not a "entry_list" response, just return
    return @response unless @response && @response["entry_list"]
    
    objects = []
    @response["entry_list"].each do |object|
      attributes = []
      _module    = resolve_module(object)
      attributes = flatten_name_value_list(object)
      namespace = @session.namespace_const
      if namespace.const_get(_module)
        if attributes.length == 0
          raise AttributeParsingError, "response contains objects without attributes!"
        end
        objects << namespace.const_get(_module).new(attributes) 
      else
        raise InvalidModule, "#{_module} does not exist, or is not accessible"
      end
    end
    # If we only have one result, just return the object
    if objects.length == 1 && !@options[:always_return_array]
      return objects[0]
    else
      return objects
    end
  end
  
  def to_json
    @response.to_json
  end
    
  def resolve_module(list)
    list["module_name"].classify
  end
  
  def flatten_name_value_list(list)
    if list["name_value_list"]
      return flatten(list["name_value_list"])
    else
      return false
    end
  end
  
  # Takes a hash like { "first_name" => {"name" => "first_name", "value" => "John"}}
  # And flattens it into {"first_name" => "John"}
  def flatten(list)
    raise ArgumentError, list[0]['value'] if list[0] && list[0]['name'] == 'warning'
    raise ArgumentError, 'method parameter must respond to #each_pair' unless list.respond_to? :each_pair
    flat_list = {}
    list.each_pair do |k,v|
      flat_list[k.to_sym] = v["value"]
    end
    flat_list
  end
end; end
