#
# Ruby Provider for Methods
#
# Instruments the CIM class Test_Method
#

module Cmpi

  # Instrument the CIM class TestMethod
  #

  class TestMethodProvider < MethodProvider
    include InstanceProviderIF
    # create new provider instance -> check with .mof file
    def initialize broker
      super broker
    end
  
  end

end
