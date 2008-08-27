#
#
#
STDERR.puts "Hello, from rcmpi_instance.rb"

require "pp"

class Cmpi_Instance
  def initialize name
    STDERR.puts "Creating Cmpi_Instance #{name}"
  end
  def enum_instance_names context, results, reference
    STDERR.puts "Running Cmpi_Instance:enum_instance_names"
    begin
      nm = reference.namespace
      object_path = Cmpi::CMPIObjectPath.new nm
      
      object_path["hello"] = "Hello,"
      results.return_objectpath object_path
      
      object_path["hello"] = "world!"
      results.return_objectpath object_path
      
      results.done
    rescue Exception
      STDERR.puts "Exception: #{$!.message}"
    end
  end
  def enum_instances context, results, reference, properties
    STDERR.puts "Running Cmpi_Instance:enum_instances"
    begin
#      pp "Context #{context}"
#      pp "Result #{results}"
#      pp "Reference #{reference}"
#      pp "Properties #{properties}"
      
      nm = reference.namespace
      pp "nm #{nm}"
      
      object_path = Cmpi::CMPIObjectPath.new nm
      
      instance = Cmpi::CMPIInstance.new object_path
      instance[:hello] = "Hello,"
      results.return_instance instance
      
      instance = Cmpi::CMPIInstance.new object_path
      instance["hello"] = "world!"
      results.return_instance instance
      
      results.done
    rescue Exception
      STDERR.puts "Exception: #{$!.message}"
    end
  end
end
