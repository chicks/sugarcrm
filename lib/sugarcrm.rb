#! /usr/bin/env ruby

module SugarCRM

Dir["#{File.dirname(__FILE__)}/sugarcrm/**/*.rb"].each { |f| load(f) }
Dir["#{File.dirname(__FILE__)}/stdlib/**/*.rb"].each { |f| load(f) }

require 'pp'
require 'ostruct'
require 'uri'
require 'net/https'
require 'openssl'
require 'digest/md5'

require 'rubygems'
require 'json'

class LoginError < RuntimeError
end

class EmptyResponse < RuntimeError
end

class UnhandledResponse < RuntimeError
end

class InvalidSugarCRMUrl < RuntimeError
end

class Base 

  URL = "/service/v2/rest.php"
  attr :url, true
  attr :user, false
  attr :pass, false
  attr :ssl, false
  attr :connection, true
  attr :session, true
  attr :debug, true
  attr :to_obj, true

  def initialize(url, user, pass, options={})
    {
      :debug  => false,
      :to_obj => true
    }.merge! options

    @user = user
    @pass = pass
    @url  = URI.parse(url)
    @debug  = options[:debug]
    @to_obj = options[:to_obj]

    # Handles http/https in url string
    @ssl  = false
    @ssl  = true if @url.scheme == "https"

    # Appends the rest.php path onto the end of the URL if it's not included
    if @url.path !~ /rest.php$/
      @url.path += URL
    end
      
    login!
    raise LoginError, "Invalid Login" unless logged_in?
  end

  def connected?
    return false unless @connection
    return false unless @connection.started?
    true
  end

  def logged_in?
    @session ? true : false
  end


  protected

    def connect!
      @connection = Net::HTTP.new(@url.host, @url.port)
      if @ssl
        @connection.use_ssl = true
        @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connection.start
    end

    def login!
      connect! unless connected?
      json = <<-EOF
        {
          \"user_auth\": {
            \"user_name\": \"#{@user}\"\,
            \"password\": \"#{OpenSSL::Digest::MD5.new(@pass)}\"\,
            \"version\": \"2\"\,
          },
          \"application\": \"\"
        }
      EOF
      json.gsub!(/^\s{8}/,'')
      response = get(:login, json)
      @session = response.id
    end

    def get(method,json)
      query =  @url.path.dup
      query << '?method=' << method.to_s
      query << '&input_type=JSON'
      query << '&response_type=JSON'
      query << '&rest_data=' << json

      if @debug 
        puts "#{method}: Request"
        puts query
        puts "\n"
      end
      response = @connection.get(URI.escape(query))

      case response
        when Net::HTTPOK 
          raise EmptyResponse unless response.body
          response_json = JSON.parse response.body
          return false if response_json["result_count"] == 0
          if @debug 
            puts "#{method}: JSON Response:"
            pp response_json
            puts "\n"
          end
          response_obj = response_json.to_obj 
      
          if @to_obj
            return response_obj
          else
            return response_json
          end
        when Net::HTTPNotFound
          raise InvalidSugarCRMUrl, "#{@url} is invalid"
        else
          if @debug 
            puts "#{method}: Raw Response:"
            puts response.body
            puts "\n"
          end
          raise UnhandledResponse, "Can't handle response #{response}"
      end
    end

end

end
