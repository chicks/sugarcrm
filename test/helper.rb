require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sugarcrm'

class Test::Unit::TestCase
  # Replace these with your test instance
  URL   = "http://127.0.0.1/sugarcrm"
  USER  = "admin"
  PASS  = 'letmein' 

  def setup_connection
    SugarCRM.connect(URL, USER, PASS, {:debug => false})
  end
end
