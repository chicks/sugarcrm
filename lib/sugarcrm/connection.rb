require 'sugarcrm/connection/helper'
require 'sugarcrm/connection/connection'
require 'sugarcrm/connection/request'
require 'sugarcrm/connection/response'
Dir["#{File.dirname(__FILE__)}/connection/api/*.rb"].each { |f| load(f) }
