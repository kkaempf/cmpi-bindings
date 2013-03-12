#
# Provider RCP_EmbeddedObjectInstanceArray
# Instance Array embedded into Property via EmbeddedObjectInstanceA attribute
#
require 'syslog'

require 'cmpi/provider'

module Cmpi

  class CIM_ManagedElement < InstanceProvider
    # typemap for embedded instance
    def self.typemap
      {
        "InstanceID" => Cmpi::string,
        "Caption" => Cmpi::string,
        "Description" => Cmpi::string,
        "ElementName" => Cmpi::string,
        "Generation" => Cmpi::uint64,
      }
    end
  end
  #
  class RCP_EmbeddedObjectInstanceArray < InstanceProvider
    
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
        "InstanceID" => Cmpi::string,
        "EmbeddedObjectInstanceArray" => Cmpi::embedded_objectA,
      }
    end

    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      
      embedded = []
      (1..3).each do |i|
        # create embedded instance
        ref = Cmpi::CMPIObjectPath.new reference.namespace, "CIM_ManagedElement"
        ref.InstanceID = "id#{i}"
        ref.Caption = "Embedded caption"
        ref.Description = "Embedded description"
        ref.ElementName = "Embedded element name"
        ref.Generation = i
        embedded << Cmpi::CMPIInstance.new(ref)
      end

      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_EmbeddedObjectInstanceArray"
      if want_instance
        result = Cmpi::CMPIInstance.new result
      end
    
      # Set key properties
      
      result.InstanceID = "Hello world" # string
      unless want_instance
        yield result
        return
      end

      # Instance: Set non-key properties

      result.EmbeddedObjectInstanceArray = embedded
      yield result
    end
    public
    
    def enum_instance_names( context, result, reference )
      @trace_file.puts "enum_instance_names ref #{reference}"
      each(context, reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "enum_instances ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "enum_instances: instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "get_instance ref #{reference}, props #{properties.inspect}"
      each(context, reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
        break # only return first instance
      end
      result.done
      true
    end
    
    def create_instance( context, result, reference, newinst )
      @trace_file.puts "create_instance ref #{reference}, newinst #{newinst.inspect}"
      # Create instance according to reference and newinst
      result.return_objectpath reference
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
