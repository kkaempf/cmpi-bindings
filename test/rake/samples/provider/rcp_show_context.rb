#
# Provider RCP_ShowContext for class RCP_ShowContext:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # A class to return the CMPIContext passed by the CIMOM
  #
  class RCP_ShowContext < InstanceProvider
    
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
        "name" => Cmpi::string,
        "context" => Cmpi::stringA,
      }
    end
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_ShowContext"
STDERR.puts "*** result #{result}"
      if want_instance
        result = Cmpi::CMPIInstance.new result
STDERR.puts "*** result #{result}"
      end
      result.name = "CMPIContext"
      unless want_instance
        yield result
        return
      end
      
      # Instance: Set non-key properties
      count = context.get_entry_count
      res = []
      i = 0
      while i < count
        name, data = context[i]
        i += 1
        res << name
        res << data.to_s
      end
      # Set key properties
STDERR.puts "res #{res.inspect}"      
      result.context = res # string[]  (-> RCP_ShowContext)
      
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
