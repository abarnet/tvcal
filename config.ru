root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )
require ::File.join( root, 'assets' )

use Assets
run TVCal.new
