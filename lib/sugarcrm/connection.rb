module SugarCRM
  class Connection
    
    URL = "/service/v2/rest.php"
    
    attr :url, true
    attr :user, false
    attr :pass, false
    attr :ssl, false
    attr :session, true
    attr :connection, true
    attr :modules, false  
    attr :debug, true
    
    # This is the singleton connection class. 
    def initialize(url, user, pass, debug=false)
      @url    = URI.parse(url)
      @user   = user
      @pass   = pass
      @debug  = debug
      # Handles http/https in url string
      @ssl    = false
      @ssl    = true if @url.scheme == "https"
      # Appends the rest.php path onto the end of the URL if it's not included
      if @url.path !~ /rest.php$/
        @url.path += URL
      end
      login!
      raise SugarCRM::LoginError, "Invalid Login" unless logged_in?
      @modules = get_modules
      @modules.each do |m|
        begin
          register_module(m)
        rescue SugarCRM::InvalidRequest
          next
        end
      end
    end
    
    # Check to see if we are logged in
    def logged_in?
      @session ? true : false
    end
    
    # Login
    def login!
      response = login
      @session = response["id"]
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
      if @ssl
        @connection.use_ssl = true
        @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connection.start
    end

    # Send a GET request to the Sugar Instance
    def get(method, json)
      request   = SugarCRM::Request.new(@url, method, json, @debug)
      response  = connection.get(request.to_s)
    
      case response
        when Net::HTTPOK 
          raise SugarCRM::EmptyResponse unless response.body
          response_json = JSON.parse response.body
          return false if response_json["result_count"] == 0
          if @debug 
            puts "#{method}: JSON Response:"
            pp response_json
            puts "\n"
          end
          return response_json
        when Net::HTTPNotFound
          raise SugarCRM::InvalidSugarCRMUrl, "#{@url} is invalid"
        when Net::HTTPInternalServerError
          raise SugarCRM::InvalidRequest, "#{request} is invalid"
        else
          if @debug 
            puts "#{method}: Raw Response:"
            puts response.body
            puts "\n"
          end
          raise SugarCRM::UnhandledResponse, "Can't handle response #{response}"
      end
    end
    
    # Dynamically register objects based on Module name
    # I.e. a SugarCRM Module named Users will generate
    # a SugarCRM::User class.
    def register_module(module_name, mod=SugarCRM)
      klass_name = module_name.singularize
      return if mod.const_defined? klass_name
      klass = Class.new(SugarCRM::Base) do
        self.module_name = module_name
      end 
      mod.const_set klass_name, klass
      klass
    end
    
  end
end