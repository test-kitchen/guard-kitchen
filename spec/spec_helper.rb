require 'rspec'

TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$: << File.expand_path(File.dirname(__FILE__))
#$: << File.expand_path(File.join(TOPDIR, "lib"))

RSpec.configure do |c|
end
