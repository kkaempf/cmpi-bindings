#
# Provider RCP_PassCData for class RCP_PassCData:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # Passing CDATA string property values
  #
  class RCP_PassCData < InstanceProvider
    
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
        "Strange" => Cmpi::string,
        "CData" => Cmpi::string,
        "XmlData" => Cmpi::string,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      if want_instance
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_PassCData"
        result = Cmpi::CMPIInstance.new result
      else
        result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_PassCData"
      end
      
      # Set key properties
      
      result.Name = nil # string  (-> RCP_PassCData)
      unless want_instance
        yield result
        return
      end
      
      # Instance: Set non-key properties
      
      # result.Strange = nil # string  (-> RCP_PassCData)
      # result.CData = nil # string  (-> RCP_PassCData)
      # result.XmlData = nil # string  (-> RCP_PassCData)
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
