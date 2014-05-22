module SugarCRM; class Connection

  URL = "/service/v2/rest.php"
  # Set this to filter out debug output on a certain method (i.e. get_modules, or get_fields)
  DONT_SHOW_DEBUG_FOR = []
  RESPONSE_IS_NOT_JSON = [:get_user_id, :get_user_team_id]
  
  attr_accessor :url, :session, :sugar_session_id, :connection, :options, :request, :response, :errors
  attr_reader :user, :pass

  
  # This is the singleton connection class. 
  def initialize(url, user, pass, options={})
    @options  = {
      :debug => false,
      :register_modules => true,
      :load_environment => true
    }.merge(options)
    @errors   = []
    @url      = URI.parse(url)
    @user     = user
    @pass     = pass
    @request  = ""
    @response = ""
    resolve_url
    login!
    self
  end
  
  # Check to see if we are logged in
  def logged_in?
    connect! unless connected?
    @sugar_session_id ? true : false
  end
  
  # Login
  def login!
    @sugar_session_id = login["id"]
    raise SugarCRM::LoginError, "Invalid Login" unless logged_in?
  end
  
  def logout
    logout
    @sugar_session_id = nil
  end

  # Check to see if we are connected
  def connected?
    return false unless @connection
    return false unless @connection.started?
    true
  end
  
  # Connect
  def connect!
    @connection = Net::HTTP.new(@url.host, @url.port)
    if @url.scheme == "https"
      @connection.use_ssl = true
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # Ruby 1.9.3 will throw an error if server does not recognize
    # SSLv2 hello message - http://bugs.ruby-lang.org/issues/5110
    # So catch OpenSSL::SSL::SSLError and set version to SSLv3 and
    # try again
    begin
      @connection.start
    rescue OpenSSL::SSL::SSLError 
      @connection.ssl_version="SSLv3"
      @connection.start
    end
  end
  alias :reconnect! :connect!
  
  # Send a request to the Sugar Instance
  def send!(method, json, max_retry=3)
    if max_retry == 0
      raise SugarCRM::RetryLimitExceeded, "SugarCRM::Connection Errors: \n#{@errors.reverse.join "\n\s\s"}"
    end
    @request  = SugarCRM::Request.new(@url, method, json, @options[:debug])
    # Send Ze Request
    begin
      if @request.length > 3900
        @response = @connection.post(@url.path, @request)
      else
        @response = @connection.get(@url.path.dup + "?" + @request.to_s)
      end
      return handle_response
    # Timeouts are usually a server side issue
    rescue Timeout::Error => error
      @errors << error
      send!(method, json, max_retry.pred)
    # Lower level errors requiring a reconnect
    rescue Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE, EOFError => error
      @errors << error
      reconnect!
      send!(method, json, max_retry.pred)
    # Handle invalid sessions
    rescue SugarCRM::InvalidSession => error
      @errors << error
      old_session = @sugar_session_id.dup
      login!
      # Update the session id in the request that we want to retry.
      json.gsub!(old_session, @sugar_session_id)
      send!(method, json, max_retry.pred)
    end    
  end
  alias :retry! :send!
  
  def debug=(debug)
    options[:debug] = debug
  end
  
  def debug?
    options[:debug]
  end
  
  private
  
  def handle_response
    case @response
    when Net::HTTPOK 
      return process_response
    when Net::HTTPNotFound
      raise SugarCRM::InvalidSugarCRMUrl, "#{@url} is invalid"
    when Net::HTTPInternalServerError
      raise SugarCRM::InvalidRequest, "#{@request} is invalid"
    else
      if @options[:debug]
        puts "#{@request.method}: Raw Response:"
        puts @response.body
        puts "\n"
      end
      raise SugarCRM::UnhandledResponse, "Can't handle response #{@response}"
    end
  end

  def process_response
    empty_body?
    if response_contains_json?
      return parse_response
    else
      return @response.body
    end
  end
  
  def resolve_url
    # Appends the rest.php path onto the end of the URL if it's not included
    if @url.path !~ /rest.php$/
      @url.path += URL
    end
  end
  
  # Complain if our body is empty.  
  def empty_body?
    raise SugarCRM::EmptyResponse unless @response.body
  end
  
  # Some methods are dumb and don't return a JSON Response
  def response_contains_json?
    if RESPONSE_IS_NOT_JSON.include? @request.method
      return false
    end
    true
  end

  def parse_response
    begin
      # Push it through the old meat grinder.
      json = JSON.parse(@response.body)
    rescue StandardError => e
      # Complain if we can't parse
      raise UnhandledResponse, @response.body
    end
    # Do ze debugs!
    nice_debugging_for json
    # Check for an invalid session
    invalid_session? json
    # Check for an empty result set
    if zero_results? json
      return nil
    end
    json
  end

  # Check if we got an invalid session error back
  # something like:
  # {"name"=>"Invalid Session ID",
  #  "number"=>11,
  #  "description"=>"The session ID is invalid"}  
  def invalid_session?(json)
    return false unless json["name"]
    return false if @request.method == :logout
    raise SugarCRM::InvalidSession if json["name"] == "Invalid Session ID"
  end
  
  def zero_results?(json)
    json["result_count"] == 0
  end
  
  # Filter debugging on REALLY BIG responses
  def nice_debugging_for(json)
    if @options[:debug] && !(DONT_SHOW_DEBUG_FOR.include? @request.method)
      puts "#{@request.method}: JSON Response:"
      pp json
      puts "\n"
    end
  end
  
end; end