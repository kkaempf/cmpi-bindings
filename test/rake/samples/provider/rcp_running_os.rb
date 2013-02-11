#
# Provider RCP_RunningOS for class RCP_RunningOS:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # Realisation of CIM_RunningOS in Ruby
  #
  #
  # RunningOS indicates the currently executing OperatingSystem. At most
  # one OperatingSystem can execute at any time on a ComputerSystem. \'At
  # most one\' is specified, since the Computer System may not be currently
  # booted, or its OperatingSystem may be unknown.
  #
  class RCP_RunningOS < AssociationProvider
    
    include InstanceProviderIF
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
    end
    
    def cleanup( context, terminating )
      @trace_file.puts "cleanup terminating? #{terminating}"
      true
    end
    
    def self.typemap
      {
        # CIM_OperatingSystem ref
        "Antecedent" => Cmpi::ref,
        # CIM_ComputerSystem ref
        "Dependent" => Cmpi::ref,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )

      cs_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ComputerSystem"
      enum = Cmpi.broker.enumInstanceNames context, cs_ref
      cs_ref = enum.next_element
      os_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_OperatingSystem"
      enum = Cmpi.broker.enumInstanceNames context, os_ref
      os_ref = enum.next_element

      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_RunningOS"
      if want_instance
	result = Cmpi::CMPIInstance.new result
      end
      # Set key properties
      result.Dependent = cs_ref # CIM_ComputerSystem
      result.Antecedent = os_ref # CIM_OperatingSystem 
      yield result

    end
    public

    # Associations
    def associator_names( context, result, reference, assoc_class, result_class, role, result_role )
      @trace_file.puts "associator_names #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}"
    end
    
    def associators( context, result, reference, assoc_class, result_class, role, result_role, properties )
      @trace_file.puts "associators #{context}, #{result}, #{reference}, #{assoc_class}, #{result_class}, #{role}, #{result_role}, #{properties}"
    end
    
    def reference_names( context, result, reference, result_class, role )
      @trace_file.puts "reference_names #{context}, #{result}, #{reference}, #{result_class}, #{role}"
      each(context, reference) do |ref|
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def references( context, result, reference, result_class, role, properties )
      @trace_file.puts "references #{context}, #{result}, #{reference}, #{result_class}, #{role}, #{properties}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
      end
      result.done
      true
    end
    
    def enum_instance_names( context, result, reference )
      @trace_file.puts "enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "get_instance ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
        break # only return first instance
      end
      result.done
      true
    end

    # query : String
    # lang : String
    def exec_query( context, result, reference, query, lang )
      @trace_file.puts "exec_query ref #{reference}, query #{query}, lang #{lang}"
      result.done
      true
    end
    
  end
end
