module SugarCRM
  
class Request

  attr :request, true
  attr :url, true
  attr :method, true
  attr :json, true

  def initialize(url, method, json, debug=false)
    @url      = url
    @method   = method
    @json     = json
  
    @request  =  @url.path.dup
    @request << '?method=' << @method.to_s
    @request << '&input_type=JSON'
    @request << '&response_type=JSON'
    @request << '&rest_data=' << @json
    
    if debug
      puts "#{method}: Request:"
      pp @request 
    end
    self
  end
  
  def to_s
    URI.escape(@request)
  end
  
end

end