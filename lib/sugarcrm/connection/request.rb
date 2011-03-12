module SugarCRM; class Request
  attr :request, true
  attr :url, true
  attr :method, true
  attr :json, true
  attr :http_method

  def initialize(url, method, json, debug=false)
    @url      = url
    @method   = method
    @json     = CGI.escape(json)
    @request  = 'method=' << @method.to_s
    @request << '&input_type=JSON'
    @request << '&response_type=JSON'
    @request << '&rest_data=' << @json
    if debug
      puts "#{method}: Request:"
      puts json 
      puts "\n"
    end
    self
  end
  
  def bytesize
    self.to_s.bytesize
  end
  
  def length
    self.to_s.length
  end
  
  def to_s
    @request
  end
end; end