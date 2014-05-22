module SugarCRM; class Request
  attr_accessor :request, :url, :method, :json
  attr_reader :http_method

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
    # BUG: SugarCRM doesn't properly handle '&quot;' inside of JSON for some reason.  Let's unescape any html elements.
    j = convert_reserved_characters(json)
    # Now we escape the resulting string.
    j = CGI.escape(j)
    j
  end
  
  # TODO: Fix this so that it JSON.parse will consume it.
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
  alias :to_str :to_s
  
  # A tiny helper for converting reserved characters for html encoding
  def convert_reserved_characters(string)
    string.gsub!(/&quot;/, '\"')
    string.gsub!(/&apos;/, '\'')
    string.gsub!(/&amp;/,  '\&')
    string.gsub!(/&lt;/,   '\<')
    string.gsub!(/&lt;/,   '\>')
    string
  end
  
end; end