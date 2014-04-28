root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )
require ::File.join( root, 'assets' )

log = File.new(File.join( root, 'log/sinatra.log' ), "a+")
$stdout.reopen(log)
$stdout.sync = true # sync forces logging to be flushed to file regularly
$stderr.reopen(log)
$stderr.sync = true

run TVCal.new
