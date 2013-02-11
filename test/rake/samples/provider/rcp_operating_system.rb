#
# Provider RCP_OperatingSystem for class RCP_OperatingSystem
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # Realisation of CIM_OperatingSystem in Ruby
  #
  class RCP_OperatingSystem < InstanceProvider
    
    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
      result = Cmpi::CMPIObjectPath.new reference.namespace, "RCP_OperatingSystem"
      if want_instance
        result = Cmpi::CMPIInstance.new result
      end
      
      # Set key properties

      cs_CreationClassName = reference.CSCreationClassName
      cs_Name = reference.CSName
      unless cs_CreationClassName && cs_Name
	# Upcall to RCP_ComputerSystem
#        GC.disable
	enum = Cmpi.broker.enumInstanceNames(context, Cmpi::CMPIObjectPath.new(reference.namespace, "RCP_ComputerSystem"))
#        GC.enable
	raise "Upcall to RCP_ComputerSystem failed for RCP_OperatingSystem" unless enum.has_next
	cs = enum.next_element
	cs_CreationClassName = cs.CreationClassName
	cs_Name = cs.Name
      end
      result.CSCreationClassName = cs_CreationClassName # string MaxLen 256 (-> CIM_OperatingSystem)
      result.CSName = cs_Name # string MaxLen 256 (-> CIM_OperatingSystem)
      result.CreationClassName = "RCP_OperatingSystem" # string MaxLen 256 (-> CIM_OperatingSystem)
      releasefile = Dir["/etc/*-release"].first
      release = File.read(releasefile).split("\n") rescue nil
      result.Name = release.first if release # string MaxLen 256 (-> CIM_OperatingSystem)
      unless want_instance
        yield result
        return
      end
      
      # Instance: Set non-key properties
      result.OSType = case release.first
      when /openSUSE.*64/ then OSType.send("SUSE 64-Bit")
      when /openSUSE/ then OSType.send("SUSE")
      when /SLES.*64/ then OSType.send("SLES 64-Bit")
      when /SLES/ then OSType.send("SLES")      
      else
	result.OtherTypeDescription = release
        OSType.Other
      end
      
      #  # uint16  (-> CIM_OperatingSystem)
      release.each do |l|
	if l =~ /VERSION\s*=\s*([^\n]*)/
	  result.Version = $1.strip
	  break
	end
      end
      uptime_in_secs = File.read('/proc/uptime').match(/^(\d+\.\d+) /)[1].to_i
      time = Time.new
      result.LastBootUpTime = time - uptime_in_secs
      result.LocalDateTime = time
      result.CurrentTimeZone = time.utc_offset / 60
      result.NumberOfLicensedUsers = 0 # unlimited
      result.NumberOfUsers = IO.popen("who") { |f| f.read.split("\n").size }
      result.NumberOfProcesses = Dir["/proc/[0-9]*"].size

      result.MaxNumberOfProcesses = Process.getrlimit(Process::RLIMIT_NPROC)[-1]
      meminfo = File.open("/proc/meminfo") do |f|
	res = {}
	# MemTotal:       12329352 kB
	while f.gets =~ /([^:]+):\s+(\d+)\s+(\S+)/	
	  res[$1] = $2.to_i
	  unless $3 == "kB"
	    STDERR.puts "#{$1} is in #{$3} !"
	  end
	end
	res
      end
      result.TotalSwapSpaceSize = meminfo["SwapTotal"]
      result.TotalVirtualMemorySize = meminfo["VmallocTotal"]
      result.FreeVirtualMemory = meminfo["MemFree"] + meminfo["SwapFree"]
      result.FreePhysicalMemory = meminfo["MemFree"]
      result.TotalVisibleMemorySize = meminfo["MemTotal"]
      result.SizeStoredInPagingFiles = 0 # no paging
      result.FreeSpaceInPagingFiles = 0
      result.MaxProcessMemorySize = meminfo["VmallocTotal"]
      result.Distributed = false
      result.MaxProcessesPerUser = Process.getrlimit(Process::RLIMIT_NPROC).first

      # result.EnabledState = EnabledState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.OtherEnabledState = nil # string  (-> CIM_EnabledLogicalElement)
      # result.RequestedState = RequestedState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.EnabledDefault = EnabledDefault.Enabled # uint16  (-> CIM_EnabledLogicalElement)
      result.TimeOfLastStateChange = 0
      # result.AvailableRequestedStates = [AvailableRequestedStates.Enabled] # uint16[]  (-> CIM_EnabledLogicalElement)
      # result.TransitioningToState = TransitioningToState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      result.InstallDate = File.stat(releasefile).mtime
      # result.OperationalStatus = [OperationalStatus.Unknown] # uint16[]  (-> CIM_ManagedSystemElement)
      # result.StatusDescriptions = [nil] # string[]  (-> CIM_ManagedSystemElement)
      # Deprecated !
      # result.Status = Status.OK # string MaxLen 10 (-> CIM_ManagedSystemElement)
      # result.HealthState = HealthState.Unknown # uint16  (-> CIM_ManagedSystemElement)
      # result.CommunicationStatus = CommunicationStatus.Unknown # uint16  (-> CIM_ManagedSystemElement)
      # result.DetailedStatus = DetailedStatus.send(:"Not Available") # uint16  (-> CIM_ManagedSystemElement)
      # result.OperatingStatus = OperatingStatus.Unknown # uint16  (-> CIM_ManagedSystemElement)
      # result.PrimaryStatus = PrimaryStatus.Unknown # uint16  (-> CIM_ManagedSystemElement)
      # result.InstanceID = nil # string  (-> CIM_ManagedElement)
      # result.Caption = nil # string MaxLen 64 (-> CIM_ManagedElement)
      # result.Description = nil # string  (-> CIM_ManagedElement)
      # result.ElementName = nil # string  (-> CIM_ManagedElement)
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
    # Wrap into Method class to prevent name clashes with provider functions
    class Method
      # CIM_OperatingSystem: Reboot
      def reboot( context, result, reference, argsin, argsout )
	@trace_file.puts "reboot #{context}, #{result}, #{reference}, #{argsin}, #{argsout}"
      end
      # CIM_OperatingSystem: Shutdown
      def shutdown( context, result, reference, argsin, argsout )
	@trace_file.puts "shutdown #{context}, #{result}, #{reference}, #{argsin}, #{argsout}"
      end
      # CIM_EnabledLogicalElement: RequestStateChange
      def request_state_change( context, result, reference, argsin, argsout )
	@trace_file.puts "request_state_change #{context}, #{result}, #{reference}, #{argsin}, #{argsout}"
      end
    end
    def invoke_method( context, result, reference, method, argsin, argsout )
      @trace_file.puts "invoke_method #{context}, #{result}, #{reference}, #{method}, #{argsin}, #{argsout}"
    end
    
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
        "CSCreationClassName" => Cmpi::string,
        "CSName" => Cmpi::string,
        "CreationClassName" => Cmpi::string,
        "Name" => Cmpi::string,
        "OSType" => Cmpi::uint16,
        "OtherTypeDescription" => Cmpi::string,
        "Version" => Cmpi::string,
        "LastBootUpTime" => Cmpi::dateTime,
        "LocalDateTime" => Cmpi::dateTime,
        "CurrentTimeZone" => Cmpi::sint16,
        "NumberOfLicensedUsers" => Cmpi::uint32,
        "NumberOfUsers" => Cmpi::uint32,
        "NumberOfProcesses" => Cmpi::uint32,
        "MaxNumberOfProcesses" => Cmpi::uint32,
        "TotalSwapSpaceSize" => Cmpi::uint64,
        "TotalVirtualMemorySize" => Cmpi::uint64,
        "FreeVirtualMemory" => Cmpi::uint64,
        "FreePhysicalMemory" => Cmpi::uint64,
        "TotalVisibleMemorySize" => Cmpi::uint64,
        "SizeStoredInPagingFiles" => Cmpi::uint64,
        "FreeSpaceInPagingFiles" => Cmpi::uint64,
        "MaxProcessMemorySize" => Cmpi::uint64,
        "Distributed" => Cmpi::boolean,
        "MaxProcessesPerUser" => Cmpi::uint32,
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
    
    
    class OSType < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "MACOS" => 2,
          "ATTUNIX" => 3,
          "DGUX" => 4,
          "DECNT" => 5,
          "Tru64 UNIX" => 6,
          "OpenVMS" => 7,
          "HPUX" => 8,
          "AIX" => 9,
          "MVS" => 10,
          "OS400" => 11,
          "OS/2" => 12,
          "JavaVM" => 13,
          "MSDOS" => 14,
          "WIN3x" => 15,
          "WIN95" => 16,
          "WIN98" => 17,
          "WINNT" => 18,
          "WINCE" => 19,
          "NCR3000" => 20,
          "NetWare" => 21,
          "OSF" => 22,
          "DC/OS" => 23,
          "Reliant UNIX" => 24,
          "SCO UnixWare" => 25,
          "SCO OpenServer" => 26,
          "Sequent" => 27,
          "IRIX" => 28,
          "Solaris" => 29,
          "SunOS" => 30,
          "U6000" => 31,
          "ASERIES" => 32,
          "HP NonStop OS" => 33,
          "HP NonStop OSS" => 34,
          "BS2000" => 35,
          "LINUX" => 36,
          "Lynx" => 37,
          "XENIX" => 38,
          "VM" => 39,
          "Interactive UNIX" => 40,
          "BSDUNIX" => 41,
          "FreeBSD" => 42,
          "NetBSD" => 43,
          "GNU Hurd" => 44,
          "OS9" => 45,
          "MACH Kernel" => 46,
          "Inferno" => 47,
          "QNX" => 48,
          "EPOC" => 49,
          "IxWorks" => 50,
          "VxWorks" => 51,
          "MiNT" => 52,
          "BeOS" => 53,
          "HP MPE" => 54,
          "NextStep" => 55,
          "PalmPilot" => 56,
          "Rhapsody" => 57,
          "Windows 2000" => 58,
          "Dedicated" => 59,
          "OS/390" => 60,
          "VSE" => 61,
          "TPF" => 62,
          "Windows (R) Me" => 63,
          "Caldera Open UNIX" => 64,
          "OpenBSD" => 65,
          "Not Applicable" => 66,
          "Windows XP" => 67,
          "z/OS" => 68,
          "Microsoft Windows Server 2003" => 69,
          "Microsoft Windows Server 2003 64-Bit" => 70,
          "Windows XP 64-Bit" => 71,
          "Windows XP Embedded" => 72,
          "Windows Vista" => 73,
          "Windows Vista 64-Bit" => 74,
          "Windows Embedded for Point of Service" => 75,
          "Microsoft Windows Server 2008" => 76,
          "Microsoft Windows Server 2008 64-Bit" => 77,
          "FreeBSD 64-Bit" => 78,
          "RedHat Enterprise Linux" => 79,
          "RedHat Enterprise Linux 64-Bit" => 80,
          "Solaris 64-Bit" => 81,
          "SUSE" => 82,
          "SUSE 64-Bit" => 83,
          "SLES" => 84,
          "SLES 64-Bit" => 85,
          "Novell OES" => 86,
          "Novell Linux Desktop" => 87,
          "Sun Java Desktop System" => 88,
          "Mandriva" => 89,
          "Mandriva 64-Bit" => 90,
          "TurboLinux" => 91,
          "TurboLinux 64-Bit" => 92,
          "Ubuntu" => 93,
          "Ubuntu 64-Bit" => 94,
          "Debian" => 95,
          "Debian 64-Bit" => 96,
          "Linux 2.4.x" => 97,
          "Linux 2.4.x 64-Bit" => 98,
          "Linux 2.6.x" => 99,
          "Linux 2.6.x 64-Bit" => 100,
          "Linux 64-Bit" => 101,
          "Other 64-Bit" => 102,
          "Microsoft Windows Server 2008 R2" => 103,
          "VMware ESXi" => 104,
          "Microsoft Windows 7" => 105,
          "CentOS 32-bit" => 106,
          "CentOS 64-bit" => 107,
          "Oracle Enterprise Linux 32-bit" => 108,
          "Oracle Enterprise Linux 64-bit" => 109,
          "eComStation 32-bitx" => 110,
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
