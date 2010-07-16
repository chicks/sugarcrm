# A fancy way of iterating over an array and converting hashes to objects
class Array
  def to_obj
    # Make a deep copy of the array
    a = Marshal.load(Marshal.dump(self))
    a.each do |i|
      case i.class.to_s
        when "Hash" then i = i.to_obj
        when "Array" then i = i.to_obj
      end
    end
    a
  end
end
