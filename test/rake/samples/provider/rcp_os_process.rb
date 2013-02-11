#
# Provider RCP_OSProcess for class RCP_OSProcess:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # Realisation of CIM_OSProcess in Ruby
  #
  #
  # A link between the OperatingSystem and Process(es) running in the
  # context of this OperatingSystem.
  #
  class RCP_OSProcess < AssociationProvider
    
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
        "GroupComponent" => Cmpi::ref,
        # CIM_Process ref
        "PartComponent" => Cmpi::ref,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      os_ref = nil # OperatingSystem for result.GroupComponent
      
      # construct reference for upcall
      upref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_UnixProcess"
      refclass = reference.classname
      if refclass == "RCP_ComputerSystem"
	upref.CSCreationClassName = reference.classname
	upref.CSName = reference.Name      
      elsif refclass == "RCP_OperatingSystem"
	upref.OSCreationClassName = reference.classname
	upref.OSName = reference.Name
	os_ref = reference
      elsif refclass != "RCP_OSProcess"
	STDERR.puts "RCP_OSProcess does not serve #{reference}"
	return # not for this class
      end
      unless os_ref
	os_ref = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_OperatingSystem"
	enum = Cmpi.broker.enumInstanceNames context, os_ref
	os_ref = enum.next_element
      end

      enum = Cmpi.broker.enumInstanceNames context, upref
      enum.each do |res|
	if want_instance
	  result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_OSProcess"
	  result = Cmpi::CMPIInstance.new result
	else
	  result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_OSProcess"
	end
      
	# Set key properties
	result.GroupComponent = os_ref # CIM_OperatingSystem
	result.PartComponent = res # CIM_Process
	yield result
      end
    end
    public

    # Associations
    def associator_names( context, result, reference, assoc_class, result_class, role, result_role )
      @trace_file.puts "RCP_OSProcess.associator_names #{context}, #{result}, ref #{reference}, assoc_class #{assoc_class}, result_class #{result_class}, role #{role}, result_role #{result_role}"
    end
    def associators( context, result, reference, assoc_class, result_class, role, result_role, properties )
      @trace_file.puts "RCP_OSProcess.associators #{context}, #{result}, ref #{reference}, assoc_class #{assoc_class}, result_class #{result_class}, role #{role}, result_role #{result_role}, props #{properties}"
    end
    #
    # Calling reference_names for RCP_ComputerSystem calls:
    #   RCP_OSProcess.reference_names ref root/cimv2:RCP_ComputerSystem.CreationClassName="RCP_ComputerSystem",Name="linux-lkbf.site", result_class , role 
    #
    # Calling reference_names for RCP_OperatingSystem calls:
    # RCP_OSProcess.reference_names ref root/cimv2:RCP_OperatingSystem.CreationClassName="RCP_OperatingSystem",CSName="linux-lkbf.site",CSCreationClassName="RCP_ComputerSystem",Name="openSUSE 11.4 (x86_64)", result_class , role 
    
    def reference_names( context, result, reference, result_class, role )
      @trace_file.puts "RCP_OSProcess.reference_names ctx #{context}, res #{result}, ref #{reference}, result_class #{result_class}, role #{role}"
      @trace_file.puts "Called from #{reference.CreationClassName}"

      each(context, reference) do |ref|
        result.return_objectpath ref
      end
      result.done
      true
    end

    def references( context, result, reference, result_class, role, properties )
      @trace_file.puts "RCP_OSProcess.references #{context}, #{result}, ref #{reference}, result_class #{result_class}, role #{role}, props #{properties}"
      each(context, reference, properties, true) do |instance|
        result.return_instance instance
      end
      result.done
      true
    end
    
    # Instance

    def create_instance( context, result, reference, newinst )
      @trace_file.puts "create_instance ref #{reference}, newinst #{newinst.inspect}"
      # RCP_OSProcess.new reference, newinst
      # result.return_objectpath reference
      # result.done
      # true
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
    
    def set_instance( context, result, reference, newinst, properties )
      @trace_file.puts "set_instance ref #{reference}, newinst #{newinst.inspect}, props #{properties.inspect}"
      properties.each do |prop|
        newinst.send "#{prop.name}=".to_sym, FIXME
      end
      result.return_instance newinst
      result.done
      true
    end
    
    def delete_instance( context, result, reference )
      @trace_file.puts "delete_instance ref #{reference}"
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
