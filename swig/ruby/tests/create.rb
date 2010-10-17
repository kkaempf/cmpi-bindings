#
# provider creation
#

$:.unshift(File.join(File.dirname(__FILE__),".."))

require 'cmpi'

Cmpi::location = File.join(File.dirname(__FILE__),"providers")

Cmpi::create_provider "SampleProvider", nil, nil
