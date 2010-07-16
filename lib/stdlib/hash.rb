# A fancy way of iterating over a hash and converting hashes to objects
class Hash
  def to_obj
    o = Object.new
    self.each do |k,v|
      # If we're looking at a hash or array, we need to look through them and convert any hashes to objects as well
      case v.class.to_s
        when "Hash"  then v = v.to_obj
        when "Array" then v = v.to_obj
      end
      o.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair
      o.class.send(:define_method, k, proc{o.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
      o.class.send(:define_method, "#{k}=", proc{|v| o.instance_variable_set("@#{k}", v)})  ## create the setter that sets the instance variable
    end
    o
  end
end