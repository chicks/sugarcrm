#! /usr/bin/env ruby

module SugarCRM

Dir["#{File.dirname(__FILE__)}/sugarcrm/**/*.rb"].each { |f| load(f) }

require 'pp'
require 'uri'
require 'net/https'
require 'digest/md5'

require 'rubygems'
require 'active_support/core_ext'
require 'json'
require 'json/add/rails'

class Base 
  # Unset all of the instance methods we don't need.
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$|^define_method$|^class$|^instance_of.$)/ }

  # This holds our connection
  cattr_accessor :connection, :instance_writer => false
  
  # Contains the name of the module in SugarCRM
  class_attribute :module_name
  self.module_name = self.name.split(/::/)[-1]
  
  # Contains the fields found on the current module
  class_attribute :module_fields
  self.module_fields = {}
  
  # Tracks if we have extended our class with attribute methods yet.
  class_attribute :attribute_methods_generated
  self.attribute_methods_generated = false

  # Contains a list of attributes
  attr :attributes, true
  attr :debug, true

  def self.establish_connection(url, user, pass, opts={})
    options = { 
      :debug  => false,
    }.merge(opts)
    @debug  = options[:debug]
    @@connection = SugarCRM::Connection.new(url, user, pass, @debug)
  end
  
  # Registers the module fields on the class
  def self.register_module_fields
    self.module_fields = connection.get_fields(self.module_name)["module_fields"] if self.module_fields.length == 0
  end
  
  def initialize(attributes={})
    @attributes = attributes_from_module_fields.merge(attributes)
    define_attribute_methods
  end

  protected

  # Generates get/set methods for keys in the attributes hash
  def define_attribute_methods
    return if attribute_methods_generated?
    @attributes.each_pair do |k,v|
      self.class.module_eval %Q?
      def #{k}
        read_attribute :#{k}
      end
      def #{k}=(value)
        write_attribute :#{k},value
      end
      ?
    end
    self.class.attribute_methods_generated = true
  end

  # Wrapper around class attribute
  def attribute_methods_generated?
    self.class.attribute_methods_generated
  end
  
  def module_fields_registered?
    self.class.module_fields.length > 0
  end

  # Returns a hash of the module fields from the 
  def attributes_from_module_fields
    self.class.register_module_fields unless module_fields_registered?
    fields = {}
    self.class.module_fields.keys.sort.each do |k|
      fields[k.to_s] = nil
    end
    fields
  end

  # Wrapper around attributes hash
  def read_attribute(key)
    @attributes[key]
  end
  
  # Wrapper around attributes hash
  def write_attribute(key, value)
    @attributes[key] = value
  end

end

end
