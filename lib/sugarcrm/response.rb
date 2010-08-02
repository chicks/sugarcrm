module SugarCRM
  # takes a raw JSON response and turns it into a REAL object
  class Response
    
    attr :response, false
    attr :module, false
    attr :attributes, false
    attr :object, false
    attr :id, false
    
    def initialize(json)
      @response   = json
      @module     = @response["entry_list"][0]["module_name"].singularize
      @attributes = flatten(@response["entry_list"][0]["name_value_list"])
      @object     = SugarCRM.const_get(@module).new(@attributes) if SugarCRM.const_get(@module)
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