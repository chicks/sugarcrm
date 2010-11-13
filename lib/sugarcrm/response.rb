module SugarCRM
  # takes a raw JSON response and turns it into a REAL object
  class Response
    
    attr :response, false
    attr :module, false
    attr :id, false
    
    def initialize(json)
      @response   = json
      @module     = @response["entry_list"][0]["module_name"].classify
      self
    end
    
    # Tries to instantiate and return an object with the valutes
    # populated from the response
    def to_obj
      objects = []
      @response["entry_list"].each do |object|
        attributes = []
        begin
          attributes = flatten_name_value_list(object)
        rescue ArgumentError => e
        end
        if SugarCRM.const_get(@module)
          raise AttributeParsingError unless attributes.length > 0
          objects << SugarCRM.const_get(@module).new(attributes) 
        else
          raise InvalidModule, "#{@module} does not exist, or is not accessible"
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
  end
end
