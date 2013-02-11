#
# Provider RCP_ComplexMethod for class RCP_ComplexMethod:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # A class to implement complex methods
  #
  class RCP_ComplexMethod < MethodProvider
    
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
        "Name" => Cmpi::string,
      }
    end
    
    # Methods
    
    # RCP_ComplexMethod: uint32 InOut(...)
    #
    def in_out_args; [["count", Cmpi::uint32, "str", Cmpi::string],[Cmpi::uint32, "result", Cmpi::string]] end
    #
    # A method to concatenate count * str, passing theresult via an out
    # parameter. Returning the result length
    #
    # Input args
    #  count : uint32
    #  str : string
    #
    # Additional output args
    #  result : string
    #
    def in_out( context, reference, count, str )
      @trace_file.puts "in_out #{context}, #{reference}, #{count.inspect}, #{str.inspect}"
      result = str * count # string
      return_value = result.size # uint32

      return [return_value, result]
    end
    
    # RCP_ComplexMethod: uint32 Size(...)
    #
    # type information for Size(...)
    def size_args; [["strA", Cmpi::stringA],[Cmpi::uint32, ]] end
    #
    # Input args
    #  strA : string[]
    #
    # Additional output args
    #
    def size( context, reference, str_a )
      @trace_file.puts "size #{context}, #{reference}, #{str_a.inspect}"
      str_a ||= []
      method_return_value = str_a.size # uint32
      
      #  function body goes here
      
      return method_return_value
    end
    
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      if want_instance
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ComplexMethod"
        result = Cmpi::CMPIInstance.new result
      else
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ComplexMethod"
      end
      
      # Set key properties
      
      result.Name = "Method" # string  (-> RCP_ComplexMethod)
      unless want_instance
        yield result
        return
      end
      
      # Instance: Set non-key properties
      
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
