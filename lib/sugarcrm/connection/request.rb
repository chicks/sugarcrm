module SugarCRM; class Request
  attr :request, true
  attr :url, true
  attr :method, true
  attr :json, true
  attr :http_method

  def initialize(url, method, json, debug=false)
    @url      = url
    @method   = method
    @json     = escape(json)
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
  
  def escape(json)
    # BUG: SugarCRM doesn't properly handle '&quot;' inside of JSON for some reason.  Let's convert it back just in case.
    j = CGI.unescapeHTML(json)
    # Now we convert everything else.
    j = CGI.escape(j)
    j
  end
  
  # TODO: Fix this so that it parses.
  def unescape
    j = CGI.unescape(@json)
    j.gsub!(/\n/, '')
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