#
# Provider RCP_Processor for class RCP_Processor
#
require 'syslog'

require 'cmpi/provider'

require 'socket'

module Cmpi
  #
  # Realisation of CIM_Processor in Ruby
  #
  class RCP_Processor < InstanceProvider
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( reference, properties = nil, want_instance = false )
      dmi = {}
      if want_instance
	IO.popen("dmidecode -t processor") do |f|
	  k = nil
	  while l = f.gets
	    if l =~ /^\s*([^:]+):\s*(.*)\s*$/
	      if $1
		k = $1
		if $2.empty?
		  dmi[k] = []
		else
		  dmi[k] = $2.strip
		end
	      end
	    elsif k
	      dmi[k] << l.strip
	    end
	  end
	end
      end
      device_id = reference.DeviceID rescue nil
      File.open("/proc/cpuinfo") do |f|
	result = nil
	next_cpu = true
	while l = f.gets
	  k,v = l.chomp.split ":"
	  next unless k
	  k.strip!
	  v.strip! if v
	  if k =~ /processor/
	    yield result if result
	    if device_id
	      next unless device_id == v
	    end
	    if want_instance
	      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_Processor"
	      result = Cmpi::CMPIInstance.new result
	    else
	      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_Processor"
	    end
	    result.SystemCreationClassName = "RCP_Processor"
	    result.SystemName = Socket.gethostbyname(Socket.gethostname).first
	    result.CreationClassName = result.SystemCreationClassName
	    result.DeviceID = v
	    next_cpu = true
	  end # /processor/
	  next unless result && want_instance
	  if next_cpu
	    result.Role = dmi["Type"]
	    result.UpgradeMethod = UpgradeMethod.send(dmi["Upgrade"].to_sym)
	    result.Family = Family.send(dmi["Version"].to_sym)
	    result.MaxClockSpeed = dmi["Max Speed"]
	    datawidth = (['a'].pack('P').length  > 4) ? 64 : 32
	    result.DataWidth = datawidth
	    result.UniqueID = dmi["ID"]
	    result.CPUStatus = (dmi["Status"] =~ /Enabled/) ? 1 : 0
	    result.ExternalBusClockSpeed = dmi["External Clock"]
	    result.NumberOfEnabledCores = dmi["Core Enabled"]
	    result.Availability = 3 # "Running/Full Power" => 3,
	    uptime_in_secs = File.read('/proc/uptime').match(/^(\d+\.\d+) /)[1].to_i
	    result.PowerOnHours = uptime_in_secs / 3600
	    result.EnabledState = EnabledState.Enabled
	    result.RequestedState = RequestedState.Enabled
	    result.EnabledDefault = EnabledDefault.Enabled
	    result.TimeOfLastStateChange = Time.now - uptime_in_secs
	    result.OperationalStatus = [OperationalStatus.OK]
	    result.HealthState = HealthState.OK
	    result.PrimaryStatus = PrimaryStatus.OK
	    result.Caption = dmi["Type"]

	    next_cpu = false
	  end # next_cpu
	  
	  case k
	  when /address sizes/ then result.AddressWidth = v
	  when /stepping/ then result.Stepping = v
	  when /cpu cores/ then result.NumberOfEnabledCores = v unless dmi["Core Enabled"]
	  when /cpu MHz/ then result.CurrentClockSpeed = v # dmi["Current Speed"] is unreliable
	  when /flags/
	    #
	    #"64-bit Capable" => 2,
	    #"32-bit Capable" => 3,
	    #"Enhanced Virtualization" => 4,
	    #"Hardware Thread" => 5,
	    #"NX-bit" => 6,
	    #"Power/Performance Control" => 7,
	    #"Core Frequency Boosting" => 8,
	    characteristics = []
	    characteristics << 2 if v.include? "lm"
	    characteristics << 3 if datawidth >= 32
	    case dmi["Manufacturer"]
	    when "Intel" then characteristics << 4 if v.include? "vmx"
	    when "AMD" then characteristics << 4 if v.include? "svm"
	    end
	    characteristics << 5 if v.include? "ht"
	    characteristics << 6 if v.include? "nx"
	    characteristics << 7 if v.include? "est"
	    result.Characteristics = characteristics
	    result.PowerManagementSupported = characteristics.include? 7
	  when /model name/
	    result.Name = v
	    result.Description = v
	    
	  # result.EnabledProcessorCharacteristics = [EnabledProcessorCharacteristics.Unknown] # uint16[] (-> CIM_Processor)
	  # Deprecated(["CIM_PowerManagementCapabilities"])result.PowerManagementSupported = nil # boolean (-> CIM_LogicalDevice)
	  # Deprecated(["CIM_PowerManagementCapabilities.PowerCapabilities"])result.PowerManagementCapabilities = [PowerManagementCapabilities.Unknown] # uint16[] (-> CIM_LogicalDevice)
	  # Deprecated(["CIM_EnabledLogicalElement.EnabledState"])result.StatusInfo = StatusInfo.Other # uint16 (-> CIM_LogicalDevice)
	  # Deprecated(["CIM_DeviceErrorData.LastErrorCode"])result.LastErrorCode = nil # uint32 (-> CIM_LogicalDevice)
	  # Deprecated(["CIM_DeviceErrorData.ErrorDescription"])result.ErrorDescription = nil # string (-> CIM_LogicalDevice)
	  # Deprecated(["CIM_ManagedSystemElement.OperationalStatus"])result.ErrorCleared = nil # boolean (-> CIM_LogicalDevice)
	  # result.OtherIdentifyingInfo = [nil] # string[] (-> CIM_LogicalDevice)
	  # result.TotalPowerOnHours = nil # uint64 (-> CIM_LogicalDevice)
	  # result.IdentifyingDescriptions = [nil] # string[] (-> CIM_LogicalDevice)
	  # result.AdditionalAvailability = [AdditionalAvailability.Other] # uint16[] (-> CIM_LogicalDevice)
	  # Deprecated(["No value"])result.MaxQuiesceTime = nil # uint64 (-> CIM_LogicalDevice)
	  # result.OtherEnabledState = nil # string (-> CIM_EnabledLogicalElement)
	  # result.AvailableRequestedStates = [AvailableRequestedStates.Enabled] # uint16[] (-> CIM_EnabledLogicalElement)
	  # result.TransitioningToState = TransitioningToState.Unknown # uint16 (-> CIM_EnabledLogicalElement)
	  # result.InstallDate = nil # dateTime (-> CIM_ManagedSystemElement)      
	  # result.StatusDescriptions = [nil] # string[] (-> CIM_ManagedSystemElement)
	  # Deprecated(["CIM_ManagedSystemElement.OperationalStatus"])result.Status = nil # string (-> CIM_ManagedSystemElement)
	  # result.CommunicationStatus = CommunicationStatus.Unknown # uint16 (-> CIM_ManagedSystemElement)
	  # result.DetailedStatus = DetailedStatus.Not Available # uint16 (-> CIM_ManagedSystemElement)
	  # result.OperatingStatus = OperatingStatus.Unknown # uint16 (-> CIM_ManagedSystemElement)      
	  # result.InstanceID = nil # string (-> CIM_ManagedElement)
	  # result.ElementName = nil # string (-> CIM_ManagedElement)
	  end # case k
	end # while
	yield result if result
      end # File.open
    end # each
    public
    
    #
    # Provider initialization
    #
    def initialize( name, broker, context )
      @trace_file = STDERR
      super broker
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
        "Role" => Cmpi::string,
        "Family" => Cmpi::uint16,
        "OtherFamilyDescription" => Cmpi::string,
        "UpgradeMethod" => Cmpi::uint16,
        "MaxClockSpeed" => Cmpi::uint32,
        "CurrentClockSpeed" => Cmpi::uint32,
        "DataWidth" => Cmpi::uint16,
        "AddressWidth" => Cmpi::uint16,
        "LoadPercentage" => Cmpi::uint16,
        "Stepping" => Cmpi::string,
        "UniqueID" => Cmpi::string,
        "CPUStatus" => Cmpi::uint16,
        "ExternalBusClockSpeed" => Cmpi::uint32,
        "Characteristics" => Cmpi::uint16A,
        "NumberOfEnabledCores" => Cmpi::uint16,
        "EnabledProcessorCharacteristics" => Cmpi::uint16A,
        "SystemCreationClassName" => Cmpi::string,
        "SystemName" => Cmpi::string,
        "CreationClassName" => Cmpi::string,
        "DeviceID" => Cmpi::string,
        "PowerManagementSupported" => Cmpi::boolean,
        "PowerManagementCapabilities" => Cmpi::uint16A,
        "Availability" => Cmpi::uint16,
        "StatusInfo" => Cmpi::uint16,
        "LastErrorCode" => Cmpi::uint32,
        "ErrorDescription" => Cmpi::string,
        "ErrorCleared" => Cmpi::boolean,
        "OtherIdentifyingInfo" => Cmpi::stringA,
        "PowerOnHours" => Cmpi::uint64,
        "TotalPowerOnHours" => Cmpi::uint64,
        "IdentifyingDescriptions" => Cmpi::stringA,
        "AdditionalAvailability" => Cmpi::uint16A,
        "MaxQuiesceTime" => Cmpi::uint64,
        "LocationIndicator" => Cmpi::uint16,
        "EnabledState" => Cmpi::uint16,
        "OtherEnabledState" => Cmpi::string,
        "RequestedState" => Cmpi::uint16,
        "EnabledDefault" => Cmpi::uint16,
        "TimeOfLastStateChange" => Cmpi::dateTime,
        "AvailableRequestedStates" => Cmpi::uint16A,
        "TransitioningToState" => Cmpi::uint16,
        "InstallDate" => Cmpi::dateTime,
        "Name" => Cmpi::string,
        "OperationalStatus" => Cmpi::uint16A,
        "StatusDescriptions" => Cmpi::stringA,
        "Status" => Cmpi::string,
        "HealthState" => Cmpi::uint16,
        "PrimaryStatus" => Cmpi::uint16,
        "DetailedStatus" => Cmpi::uint16,
        "OperatingStatus" => Cmpi::uint16,
        "CommunicationStatus" => Cmpi::uint16,
        "InstanceID" => Cmpi::string,
        "Caption" => Cmpi::string,
        "Description" => Cmpi::string,
        "ElementName" => Cmpi::string,
        "Generation" => Cmpi::uint64,
      }
    end
    
    class Family < Cmpi::ValueMap
      def self.map
        {
          "Other" => 1,
          "Unknown" => 2,
          "8086" => 3,
          "80286" => 4,
          "80386" => 5,
          "80486" => 6,
          "8087" => 7,
          "80287" => 8,
          "80387" => 9,
          "80487" => 10,
          "Pentium(R) brand" => 11,
          "Pentium(R) Pro" => 12,
          "Pentium(R) II" => 13,
          "Pentium(R) processor with MMX(TM) technology" => 14,
          "Celeron(TM)" => 15,
          "Pentium(R) II Xeon(TM)" => 16,
          "Pentium(R) III" => 17,
          "M1 Family" => 18,
          "M2 Family" => 19,
          "Intel(R) Celeron(R) M processor" => 20,
          "Intel(R) Pentium(R) 4 HT processor" => 21,
          "K5 Family" => 24,
          "K6 Family" => 25,
          "K6-2" => 26,
          "K6-3" => 27,
          "AMD Athlon(TM) Processor Family" => 28,
          "AMD(R) Duron(TM) Processor" => 29,
          "AMD29000 Family" => 30,
          "K6-2+" => 31,
          "Power PC Family" => 32,
          "Power PC 601" => 33,
          "Power PC 603" => 34,
          "Power PC 603+" => 35,
          "Power PC 604" => 36,
          "Power PC 620" => 37,
          "Power PC X704" => 38,
          "Power PC 750" => 39,
          "Intel(R) Core(TM) Duo processor" => 40,
          "Intel(R) Core(TM) Duo mobile processor" => 41,
          "Intel(R) Core(TM) Solo mobile processor" => 42,
          "Intel(R) Atom(TM) processor" => 43,
          "Alpha Family" => 48,
          "Alpha 21064" => 49,
          "Alpha 21066" => 50,
          "Alpha 21164" => 51,
          "Alpha 21164PC" => 52,
          "Alpha 21164a" => 53,
          "Alpha 21264" => 54,
          "Alpha 21364" => 55,
          "MIPS Family" => 64,
          "MIPS R4000" => 65,
          "MIPS R4200" => 66,
          "MIPS R4400" => 67,
          "MIPS R4600" => 68,
          "MIPS R10000" => 69,
          "SPARC Family" => 80,
          "SuperSPARC" => 81,
          "microSPARC II" => 82,
          "microSPARC IIep" => 83,
          "UltraSPARC" => 84,
          "UltraSPARC II" => 85,
          "UltraSPARC IIi" => 86,
          "UltraSPARC III" => 87,
          "UltraSPARC IIIi" => 88,
          "68040" => 96,
          "68xxx Family" => 97,
          "68000" => 98,
          "68010" => 99,
          "68020" => 100,
          "68030" => 101,
          "Hobbit Family" => 112,
          "Crusoe(TM) TM5000 Family" => 120,
          "Crusoe(TM) TM3000 Family" => 121,
          "Efficeon(TM) TM8000 Family" => 122,
          "Weitek" => 128,
          "Itanium(TM) Processor" => 130,
          "AMD Athlon(TM) 64 Processor Family" => 131,
          "AMD Opteron(TM) Processor Family" => 132,
          "AMD Sempron(TM) Processor Family" => 133,
          "AMD Turion(TM) 64 Mobile Technology" => 134,
          "Dual-Core AMD Opteron(TM) Processor Family" => 135,
          "AMD Athlon(TM) 64 X2 Dual-Core Processor Family" => 136,
          "AMD Turion(TM) 64 X2 Mobile Technology" => 137,
          "Quad-Core AMD Opteron(TM) Processor Family" => 138,
          "Third-Generation AMD Opteron(TM) Processor Family" => 139,
          "AMD Phenom(TM) FX Quad-Core Processor Family" => 140,
          "AMD Phenom(TM) X4 Quad-Core Processor Family" => 141,
          "AMD Phenom(TM) X2 Dual-Core Processor Family" => 142,
          "AMD Athlon(TM) X2 Dual-Core Processor Family" => 143,
          "PA-RISC Family" => 144,
          "PA-RISC 8500" => 145,
          "PA-RISC 8000" => 146,
          "PA-RISC 7300LC" => 147,
          "PA-RISC 7200" => 148,
          "PA-RISC 7100LC" => 149,
          "PA-RISC 7100" => 150,
          "V30 Family" => 160,
          "Quad-Core Intel(R) Xeon(R) processor 3200 Series" => 161,
          "Dual-Core Intel(R) Xeon(R) processor 3000 Series" => 162,
          "Quad-Core Intel(R) Xeon(R) processor 5300 Series" => 163,
          "Dual-Core Intel(R) Xeon(R) processor 5100 Series" => 164,
          "Dual-Core Intel(R) Xeon(R) processor 5000 Series" => 165,
          "Dual-Core Intel(R) Xeon(R) processor LV" => 166,
          "Dual-Core Intel(R) Xeon(R) processor ULV" => 167,
          "Dual-Core Intel(R) Xeon(R) processor 7100 Series" => 168,
          "Quad-Core Intel(R) Xeon(R) processor 5400 Series" => 169,
          "Quad-Core Intel(R) Xeon(R) processor" => 170,
          "Dual-Core Intel(R) Xeon(R) processor 5200 Series" => 171,
          "Dual-Core Intel(R) Xeon(R) processor 7200 Series" => 172,
          "Quad-Core Intel(R) Xeon(R) processor 7300 Series" => 173,
          "Quad-Core Intel(R) Xeon(R) processor 7400 Series" => 174,
          "Multi-Core Intel(R) Xeon(R) processor 7400 Series" => 175,
          "Pentium(R) III Xeon(TM)" => 176,
          "Pentium(R) III Processor with Intel(R) SpeedStep(TM) Technology" => 177,
          "Pentium(R) 4" => 178,
          "Intel(R) Xeon(TM)" => 179,
          "AS400 Family" => 180,
          "Intel(R) Xeon(TM) processor MP" => 181,
          "AMD Athlon(TM) XP Family" => 182,
          "AMD Athlon(TM) MP Family" => 183,
          "Intel(R) Itanium(R) 2" => 184,
          "Intel(R) Pentium(R) M processor" => 185,
          "Intel(R) Celeron(R) D processor" => 186,
          "Intel(R) Pentium(R) D processor" => 187,
          "Intel(R) Pentium(R) Processor Extreme Edition" => 188,
          "Intel(R) Core(TM) Solo Processor" => 189,
          "K7" => 190,
          "Intel(R) Core(TM)2 Duo Processor" => 191,
          "Intel(R) Core(TM)2 Solo processor" => 192,
          "Intel(R) Core(TM)2 Extreme processor" => 193,
          "Intel(R) Core(TM)2 Quad processor" => 194,
          "Intel(R) Core(TM)2 Extreme mobile processor" => 195,
          "Intel(R) Core(TM)2 Duo mobile processor" => 196,
          "Intel(R) Core(TM)2 Solo mobile processor" => 197,
          "Intel(R) Core(TM) i7 processor" => 198,
          "Dual-Core Intel(R) Celeron(R) Processor" => 199,
          "S/390 and zSeries Family" => 200,
          "ESA/390 G4" => 201,
          "ESA/390 G5" => 202,
          "ESA/390 G6" => 203,
          "z/Architectur base" => 204,
          "VIA C7(TM)-M Processor Family" => 210,
          "VIA C7(TM)-D Processor Family" => 211,
          "VIA C7(TM) Processor Family" => 212,
          "VIA Eden(TM) Processor Family" => 213,
          "Multi-Core Intel(R) Xeon(R) processor" => 214,
          "Dual-Core Intel(R) Xeon(R) processor 3xxx Series" => 215,
          "Quad-Core Intel(R) Xeon(R) processor 3xxx Series" => 216,
          "Dual-Core Intel(R) Xeon(R) processor 5xxx Series" => 218,
          "Quad-Core Intel(R) Xeon(R) processor 5xxx Series" => 219,
          "Dual-Core Intel(R) Xeon(R) processor 7xxx Series" => 221,
          "Quad-Core Intel(R) Xeon(R) processor 7xxx Series" => 222,
          "Multi-Core Intel(R) Xeon(R) processor 7xxx Series" => 223,
          "Embedded AMD Opteron(TM) Quad-Core Processor Family" => 230,
          "AMD Phenom(TM) Triple-Core Processor Family" => 231,
          "AMD Turion(TM) Ultra Dual-Core Mobile Processor Family" => 232,
          "AMD Turion(TM) Dual-Core Mobile Processor Family" => 233,
          "AMD Athlon(TM) Dual-Core Processor Family" => 234,
          "AMD Sempron(TM) SI Processor Family" => 235,
          "i860" => 250,
          "i960" => 251,
          "Reserved (SMBIOS Extension)" => 254,
          "Reserved (Un-initialized Flash Content - Lo)" => 255,
          "SH-3" => 260,
          "SH-4" => 261,
          "ARM" => 280,
          "StrongARM" => 281,
          "6x86" => 300,
          "MediaGX" => 301,
          "MII" => 302,
          "WinChip" => 320,
          "DSP" => 350,
          "Video Processor" => 500,
          "Reserved (For Future Special Purpose Assignment)" => 65534,
          "Reserved (Un-initialized Flash Content - Hi)" => 65535,
        }
      end
    end
    
    class UpgradeMethod < Cmpi::ValueMap
      def self.map
        {
          "Other" => 1,
          "Unknown" => 2,
          "Daughter Board" => 3,
          "ZIF Socket" => 4,
          "Replacement/Piggy Back" => 5,
          "None" => 6,
          "LIF Socket" => 7,
          "Slot 1" => 8,
          "Slot 2" => 9,
          "370 Pin Socket" => 10,
          "Slot A" => 11,
          "Slot M" => 12,
          "Socket 423" => 13,
          "Socket A (Socket 462)" => 14,
          "Socket 478" => 15,
          "Socket 754" => 16,
          "Socket 940" => 17,
          "Socket 939" => 18,
          "Socket mPGA604" => 19,
          "Socket LGA771" => 20,
          "Socket LGA775" => 21,
          "Socket S1" => 22,
          "Socket AM2" => 23,
          "Socket F (1207)" => 24,
          "Socket LGA1366" => 25,
        }
      end
    end
    
    class CPUStatus < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "CPU Enabled" => 1,
          "CPU Disabled by User" => 2,
          "CPU Disabled By BIOS (POST Error)" => 3,
          "CPU Is Idle" => 4,
          "Other" => 7,
        }
      end
    end
    
    class Characteristics < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "DMTF Reserved" => 1,
          "64-bit Capable" => 2,
          "32-bit Capable" => 3,
          "Enhanced Virtualization" => 4,
          "Hardware Thread" => 5,
          "NX-bit" => 6,
          "Power/Performance Control" => 7,
          "Core Frequency Boosting" => 8,
          # "DMTF Reserved" => 9..32567,
          # "Vendor Reserved" => 32568..65535,
        }
      end
    end
    
    class EnabledProcessorCharacteristics < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Enabled" => 2,
          "Disabled" => 3,
          "Not Applicable" => 4,
          # "DMTF Reserved" => 5..32767,
          # "Vendor Reserved" => 32768..65535,
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
    
    class Availability < Cmpi::ValueMap
      def self.map
        {
          "Other" => 1,
          "Unknown" => 2,
          "Running/Full Power" => 3,
          "Warning" => 4,
          "In Test" => 5,
          "Not Applicable" => 6,
          "Power Off" => 7,
          "Off Line" => 8,
          "Off Duty" => 9,
          "Degraded" => 10,
          "Not Installed" => 11,
          "Install Error" => 12,
          "Power Save - Unknown" => 13,
          "Power Save - Low Power Mode" => 14,
          "Power Save - Standby" => 15,
          "Power Cycle" => 16,
          "Power Save - Warning" => 17,
          "Paused" => 18,
          "Not Ready" => 19,
          "Not Configured" => 20,
          "Quiesced" => 21,
        }
      end
    end
    
    class StatusInfo < Cmpi::ValueMap
      def self.map
        {
          "Other" => 1,
          "Unknown" => 2,
          "Enabled" => 3,
          "Disabled" => 4,
          "Not Applicable" => 5,
        }
      end
    end
    
    class AdditionalAvailability < Cmpi::ValueMap
      def self.map
        {
          "Other" => 1,
          "Unknown" => 2,
          "Running/Full Power" => 3,
          "Warning" => 4,
          "In Test" => 5,
          "Not Applicable" => 6,
          "Power Off" => 7,
          "Off Line" => 8,
          "Off Duty" => 9,
          "Degraded" => 10,
          "Not Installed" => 11,
          "Install Error" => 12,
          "Power Save - Unknown" => 13,
          "Power Save - Low Power Mode" => 14,
          "Power Save - Standby" => 15,
          "Power Cycle" => 16,
          "Power Save - Warning" => 17,
          "Paused" => 18,
          "Not Ready" => 19,
          "Not Configured" => 20,
          "Quiesced" => 21,
        }
      end
    end
    
    class LocationIndicator < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "On" => 2,
          "Off" => 3,
          "Not Supported" => 4,
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
          # "DMTF Reserved" => ..,
          # "Vendor Reserved" => 0x8000..,
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
  end
end
