#
# Ruby Provider for Associations
#
# Instruments the CIM class Test_Assoc
#

module Cmpi

  # Instrument the CIM class TestAssoc
  #
  #    

  class TestAssociationProvider < AssociationProvider
#    require 'Test_Assoc'
    include InstanceProviderIF

    # create new provider instance -> check with .mof file
    def initialize broker
      super
    end
    
  end

end
