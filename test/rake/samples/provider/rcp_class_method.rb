#
# Provider RCP_ClassMethod for class RCP_ClassMethod:CIM::Class
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # A class method
  #
  class RCP_ClassMethod < MethodProvider
    
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
      }
    end
    
    # Methods
    
    # RCP_ClassMethod: string Classname(...)
    #
    # type information for Classname(...)
    def classname_args; [[],[Cmpi::string, ]] end
    #
    # Input args
    #
    # Additional output args
    #
    def classname( context, reference )
      @trace_file.puts "classname #{context}, #{reference}"
      method_return_value = "RCP_ClassMethod" # string
      
      #  function body goes here
      
      return method_return_value
    end
    
    
  end
end
