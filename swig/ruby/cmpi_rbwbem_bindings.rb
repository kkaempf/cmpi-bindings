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
    # FIXME: might allow other pathes besides RBCIMPATH
    $:.unshift RBCIMPATH # add to load path

    # CamelCase -> under_score
    underscore = classname.
	           gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
		   gsub(/([a-z\d])([A-Z])/,'\1_\2').
		   tr("-", "_").
		   downcase
    STDERR.puts "create_provider #{classname}: #{underscore}"
    
    begin
    # load implementation
      require underscore
    rescue Exception
      STDERR.puts "Loading /usr/lib/rbcim/#{underscore}.rb failed: #{$!.message}"
      raise
    end
    $:.shift # take load path away

    Cmpi.const_get(classname).new broker
  end
  
  def not_implemented klass, name
    STDERR.puts "#{klass}.#{name}: not implemented"
    nil
  end
  
  # define MI provider interfaces as modules
  #  so they can be used as mixins
  #
  # Typing information about interface function parameters
  #
  # context : CMPIContext
  # result : CMPIResult
  # reference : CMPIObjectPath
  # properties : Array of String
  #
  
  
  # Instance provider interface
  #
  # Typing information about interface function parameters
  #
  # newinst : CMPIInstance
  #
  module InstanceProviderIF
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

  # Method provider interface
  #
  module MethodProviderIF
    # method : String
    # inargs : CMPIArgs
    # outargs : CMPIArgs
    def invoke_method context, result, reference, method, inargs, outargs
    end
  end
  
  # Association provider interface
  #
  # Typing information about interface function parameters
  #
  # assoc_class : String
  # result_class : String
  # role : String
  # result_role : String
  #
  module AssociationProviderIF
    def associator_names context, result, reference, assoc_class, result_class, role, result_role
    end
    def associators context, result, reference, assoc_class, result_class, role, result_role, properties
    end
    def reference_names context, result, reference, result_class, role
    end
    def references context, result, reference, result_class, role, properties
    end
  end
  
  # Indication provider interface
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

  # now define MI classes, so implementations can be derived from them
  class InstanceProvider
    include InstanceProviderIF
    def initialize broker
      @broker = broker
    end
    def self.method_missing method, *args
      not_implemented self.class, self.method
    end
  end
  class MethodProvider
    include MethodProviderIF
    def initialize broker
      @broker = broker
    end
    def self.method_missing method, *args
      not_implemented self.class, self.method
    end
  end
  class AssociationProvider
    include AssociationProviderIF
    def initialize broker
      @broker = broker
    end
    def self.method_missing method, *args
      not_implemented self.class, self.method
    end
  end
  class IndicationProvider
    include IndicationProviderIF
    def initialize broker
      @broker = broker
    end
    def self.method_missing method, *args
      not_implemented self.class, self.method
    end
  end

end
