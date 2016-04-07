require 'pathname'

lib = Pathname.new(__FILE__).parent.parent.join('lib')
$LOAD_PATH << lib

require 'sprout/reactor'
