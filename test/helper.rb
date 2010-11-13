require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sugarcrm'

class Test::Unit::TestCase
  # Replace these with your test instance
  URL   = "http://valet/sugarcrm6"
  USER  = "admin"
  PASS  = 'letmein' 

  def setup_connection
    SugarCRM::Base.establish_connection(URL, USER, PASS, {:debug => true})
  end
end
