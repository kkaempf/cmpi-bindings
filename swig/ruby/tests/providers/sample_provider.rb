#
# sample_provider.rb
#

$:.unshift(File.join(File.dirname(__FILE__),".."))

require 'cmpi'
require 'cmpi/provider'

class SampleProvider < Cmpi::InstanceProvider
end