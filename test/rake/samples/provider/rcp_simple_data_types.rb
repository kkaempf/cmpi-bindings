#
# Provider RCP_SimpleDataTypes for class RCP_SimpleDataTypes:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # A dummy class to represent various data types
  #
  class RCP_SimpleDataTypes < InstanceProvider
    
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
        "Name" => Cmpi::string,
        "bool" => Cmpi::boolean,
        "text" => Cmpi::string,
        "char_16" => Cmpi::char16,
        "unsigned_int_8" => Cmpi::uint8,
        "unsigned_int_16" => Cmpi::uint16,
        "unsigned_int_32" => Cmpi::uint32,
        "unsigned_int_64" => Cmpi::uint64,
        "byte" => Cmpi::sint8,
        "short" => Cmpi::sint16,
        "int" => Cmpi::sint32,
        "long" => Cmpi::sint64,
        "float" => Cmpi::real32,
        "double" => Cmpi::real64,
        "date_time" => Cmpi::dateTime,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      if want_instance
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_SimpleDataTypes"
        result = Cmpi::CMPIInstance.new result
      else
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_SimpleDataTypes"
      end
      
      # Set key properties
      
      result.Name = "Sample"
      unless want_instance
        yield result
        return
      end
      
      # Instance: Set non-key properties
      
      result.bool = true
      result.text = "This is new text"
      result.char_16 = 65535
      result.unsigned_int_8 = 123
      result.unsigned_int_16 = 12345
      result.unsigned_int_32 = 1234567890
      result.unsigned_int_64 = 1234567891011121314
      result.byte = -1
      result.short = -1
      result.int = -1
      result.long = -1
      result.float = 3.142592653
      result.double = Math::PI
      result.date_time = Time.now #0
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
        @trace_file.puts "instance #{instance}"
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
