#
# Provider RCP_ComputerSystem for class RCP_ComputerSystem
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # Realisation of CIM_ComputerSystem in Ruby
  #
  class RCP_ComputerSystem < InstanceProvider
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( reference, properties = nil, want_instance = false )
#      require 'socket'

      result = Cmpi::CMPIObjectPath.new reference.namespace, reference.classname
      if want_instance
	result = Cmpi::CMPIInstance.new result
      end

      # Set key properties
      
      result.CreationClassName = "RCP_ComputerSystem" # string (-> CIM_System)
      result.Name = "hostname" #Socket.gethostbyname(Socket.gethostname).first
      unless want_instance
        yield result
        return
      end
      
      # Set non-key properties

      result.NameFormat = NameFormat.Other # string (-> CIM_ComputerSystem)
      result.Dedicated = [Dedicated.send(:"Not Dedicated")] # uint16[] (-> CIM_ComputerSystem)
      # result.OtherDedicatedDescriptions = [nil] # string[] (-> CIM_ComputerSystem)
      # result.ResetCapability = ResetCapability.Other # uint16 (-> CIM_ComputerSystem)
      # Deprecated(["CIM_PowerManagementCapabilities.PowerCapabilities"])result.PowerManagementCapabilities = [PowerManagementCapabilities.Unknown] # uint16[] (-> CIM_ComputerSystem)
      result.PrimaryOwnerName = "root" # string (-> CIM_System)
      result.PrimaryOwnerContact = "root@#{result.Name}" # string (-> CIM_System)
      # result.Roles = [nil] # string[] (-> CIM_System)
      # result.OtherIdentifyingInfo = [nil] # string[] (-> CIM_System)
      # result.IdentifyingDescriptions = [nil] # string[] (-> CIM_System)
      result.EnabledState = EnabledState.Enabled # uint16 (-> CIM_EnabledLogicalElement)
      # result.OtherEnabledState = nil # string (-> CIM_EnabledLogicalElement)
      # result.RequestedState = RequestedState.Unknown # uint16 (-> CIM_EnabledLogicalElement)
      # result.EnabledDefault = EnabledDefault.Enabled # uint16 (-> CIM_EnabledLogicalElement)
      uptime_in_secs = File.read('/proc/uptime').match(/^(\d+\.\d+) /)[1].to_i
      result.TimeOfLastStateChange = Time.now - uptime_in_secs # dateTime (-> CIM_EnabledLogicalElement)
      # result.AvailableRequestedStates = [AvailableRequestedStates.Enabled] # uint16[] (-> CIM_EnabledLogicalElement)
      # result.TransitioningToState = TransitioningToState.Unknown # uint16 (-> CIM_EnabledLogicalElement)
      # result.InstallDate = nil # dateTime (-> CIM_ManagedSystemElement)
      result.OperationalStatus = [OperationalStatus.OK] # uint16[] (-> CIM_ManagedSystemElement)
      # result.StatusDescriptions = [nil] # string[] (-> CIM_ManagedSystemElement)
      # Deprecated(["CIM_ManagedSystemElement.OperationalStatus"])result.Status = Status.OK # string (-> CIM_ManagedSystemElement)
      # result.HealthState = HealthState.Unknown # uint16 (-> CIM_ManagedSystemElement)
      # result.CommunicationStatus = CommunicationStatus.Unknown # uint16 (-> CIM_ManagedSystemElement)
      # result.DetailedStatus = DetailedStatus.send(:"Not Available") # uint16 (-> CIM_ManagedSystemElement)
      # result.OperatingStatus = OperatingStatus.Unknown # uint16 (-> CIM_ManagedSystemElement)
      # result.PrimaryStatus = PrimaryStatus.Unknown # uint16 (-> CIM_ManagedSystemElement)
      # result.InstanceID = nil # string (-> CIM_ManagedElement)
      # result.Caption = nil # string (-> CIM_ManagedElement)
      # result.Description = nil # string (-> CIM_ManagedElement)
      # result.ElementName = nil # string (-> CIM_ManagedElement)
      yield result
    end
    public
    
    #
    # Provider initialization
    #
    def initialize( name, broker, context )      
      @trace_file = STDERR
      super broker
    end
    
    # Methods
      
    # CIM_ComputerSystem: SetPowerState
    def set_power_state_args; [["PowerState", Cmpi::uint32, "Time", Cmpi::dateTime],[Cmpi::uint32, ]] end
    #
    # A class derived from System that is a special collection of
    # ManagedSystemElements. This collection is related to the providing
    # of compute capabilities and MAY serve as an aggregation point to
    # associate one or more of the following elements: FileSystem,
    # OperatingSystem, Processor and Memory (Volatile and/or NonVolatile
    # Storage).
    #
    def set_power_state( context, reference, power_state, time )
      @trace_file.puts "set_power_state #{context}, #{reference}, #{power_state}, #{time}"
      result = 12345 # uint32
      #  function body goes here
      return result
    end
      
    # CIM_EnabledLogicalElement: RequestStateChange
    def request_state_change_args; [["RequestedState", Cmpi::uint16, "TimeoutPeriod", Cmpi::dateTime],[Cmpi::uint32, "Job", Cmpi::ref]] end
    #
    # This class extends LogicalElement to abstract the concept of an
    # element that is enabled and disabled, such as a LogicalDevice or a
    # ServiceAccessPoint.
    #
    def request_state_change( context, reference, requested_state, timeout_period )
      @trace_file.puts "request_state_change #{context}, #{reference}, #{requested_state}, #{timeout_period}"
      result = 42 # uint32
      job = Cmpi::CMPIObjectPath.new reference.namespace, "CIM_ConcreteJob" # CIM_ConcreteJob ref
      #  function body goes here
      return [result, job]
    end
      
    def enum_instance_names( context, result, reference )
      @trace_file.puts "enum_instance_names ref #{reference}"
      each(reference) do |ref|
        @trace_file.puts "ref #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end
    
    def enum_instances( context, result, reference, properties )
      @trace_file.puts "enum_instances ref #{reference}, props #{properties.inspect}"
      each(reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end
    
    def get_instance( context, result, reference, properties )
      @trace_file.puts "get_instance ref #{reference}, props #{properties.inspect}"
      each(reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
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
    
    def cleanup( context, terminating )
      @trace_file.puts "cleanup terminating? #{terminating}"
      true
    end
    
    def self.typemap
      {
        "NameFormat" => Cmpi::string,
        "Dedicated" => Cmpi::uint16A,
        "OtherDedicatedDescriptions" => Cmpi::stringA,
        "ResetCapability" => Cmpi::uint16,
        "PowerManagementCapabilities" => Cmpi::uint16A,
        "CreationClassName" => Cmpi::string,
        "Name" => Cmpi::string,
        "PrimaryOwnerName" => Cmpi::string,
        "PrimaryOwnerContact" => Cmpi::string,
        "Roles" => Cmpi::stringA,
        "OtherIdentifyingInfo" => Cmpi::stringA,
        "IdentifyingDescriptions" => Cmpi::stringA,
        "EnabledState" => Cmpi::uint16,
        "OtherEnabledState" => Cmpi::string,
        "RequestedState" => Cmpi::uint16,
        "EnabledDefault" => Cmpi::uint16,
        "TimeOfLastStateChange" => Cmpi::dateTime,
        "AvailableRequestedStates" => Cmpi::uint16A,
        "TransitioningToState" => Cmpi::uint16,
        "InstallDate" => Cmpi::dateTime,
        "OperationalStatus" => Cmpi::uint16A,
        "StatusDescriptions" => Cmpi::stringA,
        "Status" => Cmpi::string,
        "HealthState" => Cmpi::uint16,
        "CommunicationStatus" => Cmpi::uint16,
        "DetailedStatus" => Cmpi::uint16,
        "OperatingStatus" => Cmpi::uint16,
        "PrimaryStatus" => Cmpi::uint16,
        "InstanceID" => Cmpi::string,
        "Caption" => Cmpi::string,
        "Description" => Cmpi::string,
        "ElementName" => Cmpi::string,
      }
    end
    
    
    class NameFormat < Cmpi::ValueMap
      def self.map
        {
          "Other" => :Other,
          "IP" => :IP,
          "Dial" => :Dial,
          "HID" => :HID,
          "NWA" => :NWA,
          "HWA" => :HWA,
          "X25" => :X25,
          "ISDN" => :ISDN,
          "IPX" => :IPX,
          "DCC" => :DCC,
          "ICD" => :ICD,
          "E.164" => :"E.164",
          "SNA" => :SNA,
          "OID/OSI" => :"OID/OSI",
          "WWN" => :WWN,
          "NAA" => :NAA,
          "UUID" => :UUID,
        }
      end
    end
    
    class Dedicated < Cmpi::ValueMap
      def self.map
        {
          "Not Dedicated" => 0,
          "Unknown" => 1,
          "Other" => 2,
          "Storage" => 3,
          "Router" => 4,
          "Switch" => 5,
          "Layer 3 Switch" => 6,
          "Central Office Switch" => 7,
          "Hub" => 8,
          "Access Server" => 9,
          "Firewall" => 10,
          "Print" => 11,
          "I/O" => 12,
          "Web Caching" => 13,
          "Management" => 14,
          "Block Server" => 15,
          "File Server" => 16,
          "Mobile User Device" => 17,
          "Repeater" => 18,
          "Bridge/Extender" => 19,
          "Gateway" => 20,
          "Storage Virtualizer" => 21,
          "Media Library" => 22,
          "ExtenderNode" => 23,
          "NAS Head" => 24,
          "Self-contained NAS" => 25,
          "UPS" => 26,
          "IP Phone" => 27,
          "Management Controller" => 28,
          "Chassis Manager" => 29,
          "Host-based RAID controller" => 30,
          "Storage Device Enclosure" => 31,
          "Desktop" => 32,
          "Laptop" => 33,
          "Virtual Tape Library" => 34,
          "Virtual Library System" => 35,
          "Network PC/Thin Client" => 36,
          "FC Switch" => 37,
          "Ethernet Switch" => 38,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 32568..65535,
        }
      end
    end
    
    class ResetCapability < Cmpi::ValueMap
      def self.map
        {
          "Other" => 1,
          "Unknown" => 2,
          "Disabled" => 3,
          "Enabled" => 4,
          "Not Implemented" => 5,
        }
      end
    end
    
    class PowerManagementCapabilities < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Not Supported" => 1,
          "Disabled" => 2,
          "Enabled" => 3,
          "Power Saving Modes Entered Automatically" => 4,
          "Power State Settable" => 5,
          "Power Cycling Supported" => 6,
          "Timed Power On Supported" => 7,
        }
      end
    end
    
    class EnabledState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "Enabled" => 2,
          "Disabled" => 3,
          "Shutting Down" => 4,
          "Not Applicable" => 5,
          "Enabled but Offline" => 6,
          "In Test" => 7,
          "Deferred" => 8,
          "Quiesce" => 9,
          "Starting" => 10,
          # "DMTF Reserved" => 11..32767,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end
    
    class RequestedState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Enabled" => 2,
          "Disabled" => 3,
          "Shut Down" => 4,
          "No Change" => 5,
          "Offline" => 6,
          "Test" => 7,
          "Deferred" => 8,
          "Quiesce" => 9,
          "Reboot" => 10,
          "Reset" => 11,
          "Not Applicable" => 12,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end
    
    class EnabledDefault < Cmpi::ValueMap
      def self.map
        {
          "Enabled" => 2,
          "Disabled" => 3,
          "Not Applicable" => 5,
          "Enabled but Offline" => 6,
          "No Default" => 7,
          "Quiesce" => 9,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 32768..65535,
        }
      end
    end
    
    class AvailableRequestedStates < Cmpi::ValueMap
      def self.map
        {
          "Enabled" => 2,
          "Disabled" => 3,
          "Shut Down" => 4,
          "Offline" => 6,
          "Test" => 7,
          "Defer" => 8,
          "Quiesce" => 9,
          "Reboot" => 10,
          "Reset" => 11,
          # "DMTF Reserved" => ..,
        }
      end
    end
    
    class TransitioningToState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Enabled" => 2,
          "Disabled" => 3,
          "Shut Down" => 4,
          "No Change" => 5,
          "Offline" => 6,
          "Test" => 7,
          "Defer" => 8,
          "Quiesce" => 9,
          "Reboot" => 10,
          "Reset" => 11,
          "Not Applicable" => 12,
          # "DMTF Reserved" => ..,
        }
      end
    end
    
    class OperationalStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "OK" => 2,
          "Degraded" => 3,
          "Stressed" => 4,
          "Predictive Failure" => 5,
          "Error" => 6,
          "Non-Recoverable Error" => 7,
          "Starting" => 8,
          "Stopping" => 9,
          "Stopped" => 10,
          "In Service" => 11,
          "No Contact" => 12,
          "Lost Communication" => 13,
          "Aborted" => 14,
          "Dormant" => 15,
          "Supporting Entity in Error" => 16,
          "Completed" => 17,
          "Power Mode" => 18,
          "Relocating" => 19,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class Status < Cmpi::ValueMap
      def self.map
        {
          "OK" => :OK,
          "Error" => :Error,
          "Degraded" => :Degraded,
          "Unknown" => :Unknown,
          "Pred Fail" => :"Pred Fail",
          "Starting" => :Starting,
          "Stopping" => :Stopping,
          "Service" => :Service,
          "Stressed" => :Stressed,
          "NonRecover" => :NonRecover,
          "No Contact" => :"No Contact",
          "Lost Comm" => :"Lost Comm",
          "Stopped" => :Stopped,
        }
      end
    end
    
    class HealthState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "OK" => 5,
          "Degraded/Warning" => 10,
          "Minor failure" => 15,
          "Major failure" => 20,
          "Critical failure" => 25,
          "Non-recoverable error" => 30,
          # "DMTF Reserved" => ..,
          # "Vendor Specific" => 32768..65535,
        }
      end
    end
    
    class CommunicationStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Not Available" => 1,
          "Communication OK" => 2,
          "Lost Communication" => 3,
          "No Contact" => 4,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class DetailedStatus < Cmpi::ValueMap
      def self.map
        {
          "Not Available" => 0,
          "No Additional Information" => 1,
          "Stressed" => 2,
          "Predictive Failure" => 3,
          "Non-Recoverable Error" => 4,
          "Supporting Entity in Error" => 5,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class OperatingStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Not Available" => 1,
          "Servicing" => 2,
          "Starting" => 3,
          "Stopping" => 4,
          "Stopped" => 5,
          "Aborted" => 6,
          "Dormant" => 7,
          "Completed" => 8,
          "Migrating" => 9,
          "Emigrating" => 10,
          "Immigrating" => 11,
          "Snapshotting" => 12,
          "Shutting Down" => 13,
          "In Test" => 14,
          "Transitioning" => 15,
          "In Service" => 16,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
    
    class PrimaryStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "OK" => 1,
          "Degraded" => 2,
          "Error" => 3,
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
        }
      end
    end
  end
end
