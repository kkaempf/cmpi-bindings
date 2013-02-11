#
# Provider RCP_ArrayDataTypes for class RCP_ArrayDataTypes:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

STDERR.puts "\t\t *** rcp_array_data_types.rb"

module Cmpi
  #
  # A dummy class to represent array data types
  #
  class RCP_ArrayDataTypes < InstanceProvider
    
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      @trace_file.puts "#{self.class}.new #{name}"
      super broker
    end
    
    def cleanup( context, terminating )
      @trace_file.puts "cleanup terminating? #{terminating}"
      true
    end
    
    def self.typemap
      {
        "Name" => Cmpi::string,
        "bool" => Cmpi::booleanA,
        "text" => Cmpi::stringA,
        "char_16" => Cmpi::char16A,
        "unsigned_int_8" => Cmpi::uint8A,
        "unsigned_int_16" => Cmpi::uint16A,
        "unsigned_int_32" => Cmpi::uint32A,
        "unsigned_int_64" => Cmpi::uint64A,
        "byte" => Cmpi::sint8A,
        "short" => Cmpi::sint16A,
        "int" => Cmpi::sint32A,
        "long" => Cmpi::sint64A,
        "float" => Cmpi::real32A,
        "double" => Cmpi::real64A,
        "date_time" => Cmpi::dateTimeA,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      if want_instance
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ArrayDataTypes"
        result = Cmpi::CMPIInstance.new result
      else
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ArrayDataTypes"
      end
      
      @trace_file.puts "reference(#{reference.class}:#{reference})"
      ["Empty", "One", "More"].each do |name|
        
        if reference.Name
          @trace_file.puts "Expect Name = #{reference.Name.inspect}, have #{name.inspect}"
          next unless name == reference.Name
        end
        # Set key properties

        @trace_file.puts "result.Name = #{name}"
        result.Name = name # string  (-> RCP_ArrayDataTypes)
        if want_instance
        @trace_file.puts "want_instance"

        case name
        when "Empty"
          # Instance: Set non-key properties
      
          result.bool = [] # boolean[]  (-> RCP_ArrayDataTypes)
          result.text = [] # string[]  (-> RCP_ArrayDataTypes)
          result.char_16 = [] # char16[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_8 = [] # uint8[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_16 = [] # uint16[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_32 = [] # uint32[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_64 = [] # uint64[]  (-> RCP_ArrayDataTypes)
          result.byte = [] # sint8[]  (-> RCP_ArrayDataTypes)
          result.short = [] # sint16[]  (-> RCP_ArrayDataTypes)
          result.int = [] # sint32[]  (-> RCP_ArrayDataTypes)
          result.long = [] # sint64[]  (-> RCP_ArrayDataTypes)
          result.float = [] # real32[]  (-> RCP_ArrayDataTypes)
          result.double = [] # real64[]  (-> RCP_ArrayDataTypes)
          result.date_time = [] # dateTime[]  (-> RCP_ArrayDataTypes)
        when "One"
          # Instance: Set non-key properties
      
          @trace_file.puts "result for #{name}"
          result.bool = [true] # boolean[]  (-> RCP_ArrayDataTypes)
          result.text = ["One element"] # string[]  (-> RCP_ArrayDataTypes)
          result.char_16 = [65535] # char16[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_8 = [1] # uint8[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_16 = [1] # uint16[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_32 = [1] # uint32[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_64 = [1] # uint64[]  (-> RCP_ArrayDataTypes)
          result.byte = [1] # sint8[]  (-> RCP_ArrayDataTypes)
          result.short = [1] # sint16[]  (-> RCP_ArrayDataTypes)
          result.int = [1] # sint32[]  (-> RCP_ArrayDataTypes)
          result.long = [1] # sint64[]  (-> RCP_ArrayDataTypes)
          result.float = [Math::PI] # real32[]  (-> RCP_ArrayDataTypes)
          result.double = [Math::PI] # real64[]  (-> RCP_ArrayDataTypes)
          result.date_time = [Time.now] # dateTime[]  (-> RCP_ArrayDataTypes)
        when "More"
          # Instance: Set non-key properties
      
          result.bool = [true,false,true] # boolean[]  (-> RCP_ArrayDataTypes)
          result.text = ["Element one", "Element two", "Element three"] # string[]  (-> RCP_ArrayDataTypes)
          result.char_16 = ["1", "2", "3"] #[49, 50, 51] # '1','2','3' char16[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_8 = [1,2,3] # uint8[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_16 = [1,2,3] # uint16[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_32 = [1,2,3] # uint32[]  (-> RCP_ArrayDataTypes)
          result.unsigned_int_64 = [1,2,3] # uint64[]  (-> RCP_ArrayDataTypes)
          result.byte = [1,2,3] # sint8[]  (-> RCP_ArrayDataTypes)
          result.short = [1,2,3] # sint16[]  (-> RCP_ArrayDataTypes)
          result.int = [1,2,3] # sint32[]  (-> RCP_ArrayDataTypes)
          result.long = [1,2,3] # sint64[]  (-> RCP_ArrayDataTypes)
          result.float = [Math::PI,Math::PI,Math::PI] # real32[]  (-> RCP_ArrayDataTypes)
          result.double = [Math::PI,Math::PI,Math::PI] # real64[]  (-> RCP_ArrayDataTypes)
          result.date_time = [Time.now, 31536000000000, "-31536000", "19520311040242.424242-060", "12345678010203.123456:000"] # dateTime[]  (-> RCP_ArrayDataTypes)
        end
        end # if want_instance
        @trace_file.puts "\tyield #{result}"
        yield result        
      end
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
