module SugarCRM; class Response
  
  class << self
    # This class handles the response from the server.
    # It tries to convert the response into an object such as User
    # or an object collection.  If it fails, it just returns the response hash
    def handle(json)
      r = new(json)
      begin
        return r.to_obj
      rescue
        return json
      end
    end
  end

  attr :response, false
  
  def initialize(json)
    @response = json
  end
  
  # Tries to instantiate and return an object with the values
  # populated from the response
  def to_obj
    objects = []
    @response["entry_list"].each do |object|
      attributes = []
      _module    = resolve_module(object)
      begin
        attributes = flatten_name_value_list(object)
      rescue ArgumentError => e
      end
      if SugarCRM.const_get(_module)
        if attributes.length == 0
          pp object
          raise AttributeParsingError, "response contains objects without attributes!"
        end
        objects << SugarCRM.const_get(_module).new(attributes) 
      else
        raise InvalidModule, "#{_module} does not exist, or is not accessible"
      end
    end
    # If we only have one result, just return the object
    if objects.length == 1
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
    raise ArgumentError, 'method parameter must respond to #each_pair' unless list.respond_to? :each_pair
    flat_list = {}
    list.each_pair do |k,v|
      flat_list[k.to_sym] = v["value"]
    end
    flat_list
  end
end; end
