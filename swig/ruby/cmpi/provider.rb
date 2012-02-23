#
# provider.rb
#
# Provider API for cmpi-bindings-ruby, Ruby based CIM Providers
#

require 'cmpi'

module Cmpi

  #
  # Accessor for broker value passed at provider initialization
  #  Required internally for callbacks like CMNewString
  #
private
  def self.broker= broker
    @@broker = broker
  end
public
  def self.broker
    @@broker
  end
  def not_implemented klass, name
    STDERR.puts "#{klass}.#{name}: not implemented"
    nil
  end
  
  #
  # = Generic Provider interface
  #
  # Defines the interface common to all specific providers
  # * InstanceProvider
  # * MethodProvider
  # * AssociationProvider
  # * IndicationProvider
  #
  # define MI provider interfaces as modules
  # so they can be used as mixins
  #
  # Typing information about interface function parameters
  #
  # context : CMPIContext
  # result : CMPIResult
  # reference : CMPIObjectPath
  # properties : Array of String
  #
  module ProviderIF
    protected
    #
    # call-seq:
    #   ProviderIF.new broker
    #
    def initialize broker
      Cmpi::broker = broker
    end
    #
    # Cleanup provider, +terminating+: boolean
    #
    def cleanup context, terminating
    end
    def self.method_missing method, *args
      not_implemented self.class, self.method
    end
  end
  
  #
  # = Instance provider interface
  #
  # Defines the CMPI interface for Instance providers
  #
  # newinst : CMPIInstance
  #
  module InstanceProviderIF
    protected
    def create_instance context, result, reference, newinst
    end
    def enum_instance_names context, result, reference
    end
    def enum_instances context, result, reference, properties
    end
    def get_instance context, result, reference, properties
    end
    def set_instance context, result, reference, newinst, properties
    end
    def delete_instance context, result, reference
    end
    # query : String
    # lang : String 
    def exec_query context, result, reference, query, lang
    end
  end

  #
  # = Method provider interface
  #
  # Defines the CMPI interface for Method providers
  #
  #
  module MethodProviderIF
    protected
    # method : String
    # inargs : CMPIArgs
    # outargs : CMPIArgs
    def invoke_method context, result, reference, method, inargs, outargs
    end
  end
  
  #
  # = Association provider interface
  #
  # Defines the CMPI interface for Association providers
  #
  #
  # Typing information about interface function parameters
  #
  # assoc_class : String
  # result_class : String
  # role : String
  # result_role : String
  #
  module AssociationProviderIF
    protected
    def associator_names context, result, reference, assoc_class, result_class, role, result_role
    end
    def associators context, result, reference, assoc_class, result_class, role, result_role, properties
    end
    def reference_names context, result, reference, result_class, role
    end
    def references context, result, reference, result_class, role, properties
    end
  end
  
  #
  # = Indication provider interface
  #
  # Defines the CMPI interface for Indication providers
  #
  # Typing information about interface function parameters
  #
  # filter : CMPISelectExp
  # class_name : String
  # owner : String
  # first_activation : Bool
  # last_activation : Bool
  #
  module IndicationProviderIF
    protected
    def authorize_filter context, filter, class_name, reference, owner
    end
    def activate_filter context, filter, class_name, reference, first_activation
    end
    def deactivate_filter context, filter, class_name, reference, last_activation
    end
    def must_poll context, filter, class_name, reference
    end
    def enable_indications context
    end
    def disable_indications context
    end
  end

  #
  # = Instance Provider
  #
  # *Abstract* class
  #
  # == Synopsis
  #   class MyProvider < Cmpi::InstanceProvider
  #   end
  #
  # Handling instances of CIM classes
  #
  class InstanceProvider
    include ProviderIF
    include InstanceProviderIF
  end
  #
  # = Method Provider
  #
  # *Abstract* class
  #
  # Implementing methods for classes and instances
  #
  # 
  #
  class MethodProvider
    include ProviderIF
    include MethodProviderIF
  end
  #
  # = Association Provider
  #
  # *Abstract* class
  #
  # Providing (instances of) associations between instances
  #
  class AssociationProvider
    include ProviderIF
    include AssociationProviderIF
  end
  #
  # = Indication Provider
  #
  # *Abstract* class
  #
  # Providing asynchronous events
  #
  class IndicationProvider
    include ProviderIF
    include IndicationProviderIF
  end

end
