#
# provider creation
#

$:.unshift("..")

require 'cmpi_rbwbem_bindings'

Cmpi::create_provider "TestProvider", nil
