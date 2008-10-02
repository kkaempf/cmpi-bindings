#
# Module RbCmpi
#
# Main entry point for cmpi-bindings-ruby, Ruby based CIM Providers
#

module Cmpi
  # init
  RBCIMPATH = "/usr/lib/rbcim"
  
  #
  # on-demand loading of Ruby providers
  # create provider for 'classname'
  #  pass 'broker' to its constructor
  #
  def self.create_provider classname, broker
    $:.unshift RBCIMPATH # add to load path
    # CamelCase -> under_score
    underscore = classname.
	           gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
		   gsub(/([a-z\d])([A-Z])/,'\1_\2').
		   tr("-", "_").
		   downcase
    STDERR.puts "create_provider #{classname}: #{underscore}"
    # load implementation
    require underscore
    
    $:.shift # take load path away

    Cmpi.const_get(classname).new broker
  end
  
  # define MI provider interfaces as modules
  #  so they can be used as mixins
  module InstanceProviderIF
    def create_instance context, result, reference, newinst
    end
    def get_instance context, result, objname, plist
    end
    def delete_instance context, result, objname
    end
    def method_missing method, *args
      STDERR.puts "InstanceProvider.#{method}: not implemented"
    end
  end

  module MethodProviderIF
    def method_missing method, *args
      STDERR.puts "MethodProvider.#{method}: not implemented"
    end
  end
  
  module AssociationProviderIF
    def method_missing method, *args
      STDERR.puts "AssociationProvider.#{method}: not implemented"
    end
  end
  module IndicationProviderIF
    def method_missing method, *args
      STDERR.puts "IndicationProvider.#{method}: not implemented"
    end
  end

  # now define MI classes, so they can be derived from
  class InstanceProvider
    include InstanceProviderIF
    def initialize broker
      @broker = broker
    end
  end
  class MethodProvider
    include MethodProviderIF
    def initialize broker
      @broker = broker
    end
  end
  class AssociationProvider
    include AssociationProviderIF
    def initialize broker
      @broker = broker
    end
  end
  class IndicationProvider
    include IndicationProviderIF
    def initialize broker
      @broker = broker
    end
  end

end
