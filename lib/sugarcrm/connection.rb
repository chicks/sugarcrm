
require 'uri'
require 'net/https'

require 'rubygems'
require 'json'

require 'sugarcrm/connection/helper'
Dir["#{File.dirname(__FILE__)}/connection/api/*.rb"].each { |f| load(f) }

module SugarCRM; class Connection

  URL = "/service/v2/rest.php"
  DONT_SHOW_DEBUG_FOR = []
  RESPONSE_IS_NOT_JSON = [:get_user_id, :get_user_team_id]
  
  attr :url, true
  attr :user, false
  attr :pass, false
  attr :session, true
  attr :connection, true
  attr :options, true
  attr :request, true
  attr :response, true
  
  # This is the singleton connection class. 
  def initialize(url, user, pass, options={})
    @options  = {
      :debug => false,
      :register_modules => true      
    }.merge(options)
    
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
    @session ? true : false
  end
  
  # Login
  def login!
    @session = login["id"]
    raise SugarCRM::LoginError, "Invalid Login" unless logged_in?
    SugarCRM.connection = self
    SugarCRM::Base.connection = self
    Module.register_all if @options[:register_modules]
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
    @connection.start
  end
  
  # Send a GET request to the Sugar Instance
  def send!(method, json)
    @request  = SugarCRM::Request.new(@url, method, json, @options[:debug])
    if @request.length > 3900
      @response = @connection.post(@url.path, @request)
    else
      @response = @connection.get(@url.path.dup + "?" + @request.to_s)
    end
    handle_response
  end
  
  def debug=(debug)
    options[:debug] = debug
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
    # Complain if our body is empty.
    raise SugarCRM::EmptyResponse unless @response.body
    # Some methods are dumb and don't return a JSON Response
    return @response.body if RESPONSE_IS_NOT_JSON.include? @request.method
    # Push it through the old meat grinder.
    response_json = JSON.parse @response.body
    # Empty result.  Is this wise?
    return false if response_json["result_count"] == 0
    # Filter debugging on REALLY BIG responses
    if @options[:debug] && !(DONT_SHOW_DEBUG_FOR.include? @request.method)
      puts "#{@request.method}: JSON Response:"
      pp response_json
      puts "\n"
    end
    return response_json
  end
  
  def resolve_url
    # Appends the rest.php path onto the end of the URL if it's not included
    if @url.path !~ /rest.php$/
      @url.path += URL
    end
  end
  
end; end