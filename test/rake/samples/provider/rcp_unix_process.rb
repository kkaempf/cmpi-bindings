#
# Provider RCP_UnixProcess for class RCP_UnixProcess
#
require 'syslog'

require 'cmpi/provider'

module Cmpi
  #
  # Realisation of CIM_UnixProcess in Ruby
  #
  class RCP_UnixProcess < InstanceProvider

    private
    #
    # Iterator for names and instances
    #  yields references matching reference and properties
    #
    def each( context, reference, properties = nil, want_instance = false )
#      STDERR.puts "Each ref #{reference}, prop #{properties}, inst #{want_instance}"
      cs_CreationClassName = reference.CSCreationClassName
      cs_Name = reference.CSName
      unless cs_CreationClassName && cs_Name
	enum = Cmpi.broker.enumInstanceNames(context, Cmpi::CMPIObjectPath.new(reference.namespace, "RCP_ComputerSystem"))
	raise "Upcall to RCP_ComputerSystem failed for RCP_UnixProcess" unless enum.has_next
	cs = enum.next_element
	cs_CreationClassName = cs.CreationClassName
	cs_Name = cs.Name
      end
      os_CreationClassName = reference.OSCreationClassName
      os_Name = reference.OSName
      unless os_CreationClassName && os_Name
	enum = Cmpi.broker.enumInstanceNames(context, Cmpi::CMPIObjectPath.new(reference.namespace, "RCP_OperatingSystem"))
	raise "Upcall to RCP_OperatingSystem failed for RCP_UnixProcess" unless enum.has_next
	os = enum.next_element
	os_CreationClassName = os.CreationClassName
	os_Name = os.Name
      end
      pid = (reference.Handle rescue nil) || "[0-9]*"
      Dir["/proc/#{pid}"].each do |proc|
	pid = proc[6..-1]
	if want_instance
	  result = Cmpi::CMPIObjectPath.new reference.namespace, reference.classname
	  result = Cmpi::CMPIInstance.new result
	else
	  result = Cmpi::CMPIObjectPath.new reference
	end

        # Set key properties
  
        result.CSCreationClassName = cs_CreationClassName
	result.CSName = cs_Name
  
        result.OSCreationClassName = os_CreationClassName
        result.OSName = os_Name

        result.CreationClassName = "RCP_UnixProcess"
        result.Handle = pid
	unless want_instance
	  yield result
	  next
	end
  
        # Set non-key properties

	stat = File.read("#{proc}/stat").split(" ")
	#  0: pid %d      The process ID.
	#  1: comm %s     The filename of the executable, in parentheses.  This is visible whether or not the executable is swapped out.
	#  2: state %c    One  character  from  the string "RSDZTW" where R is running, S is sleeping in an interruptible wait, D is waiting in uninterruptible disk sleep, Z is zombie, T is traced or stopped (on a signal), and W is paging.
	#  3: ppid %d     The PID of the parent.
	#  4: pgrp %d     The process group ID of the process.
	#  5: session %d  The session ID of the process.
	#  6: tty_nr %d   The controlling terminal of the process.  (The minor device number is contained in the combination of bits 31 to 20 and 7 to 0; the major device number is in bits 15 to 8.)
	#  7: tpgid %d    The ID of the foreground process group of the controlling terminal of the process.
	#  8: flags %u (%lu before Linux 2.6.22)	The kernel flags word of the process.  For bit meanings, see the PF_* defines in <linux/sched.h>.  Details depend on the kernel version.
	#  9: minflt %lu  The number of minor faults the process has made which have not required loading a memory page from disk.
	# 10: cminflt %lu The number of minor faults that the process waited-for children have made.
	# 11: majflt %lu  The number of major faults the process has made which have required loading a memory page from disk.
	# 12: cmajflt %lu The number of major faults that the process waited-for children have made.
	# 13: utime %lu   Amount of time that this process has been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).  This includes guest time, guest_time (time  spent  running  a  virtual  CPU,  see below), so that applications that are not aware of the guest time field do not lose that time from their calculations.
	# 14: stime %lu   Amount of time that this process has been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
	# 15: cutime %ld  Amount  of  time  that  this  process's  waited-for  children  have  been  scheduled  in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).  (See also times(2).)  This includes guest time, cguest_time (time spent running a virtual CPU, see below).
	# 16: cstime %ld  Amount of time that this process's waited-for children have been scheduled in kernel mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
	# 17: priority %ld   (Explanation for Linux 2.6) For processes running a real-time scheduling policy (policy below; see sched_setscheduler(2)), this is the negated scheduling priority, minus one; that is, a number in the range
	#		      -2  to  -100,  corresponding  to real-time priorities 1 to 99.  For processes running under a non-real-time scheduling policy, this is the raw nice value (setpriority(2)) as represented in the kernel.  The
	#	              kernel stores nice values as numbers in the range 0 (high) to 39 (low), corresponding to the user-visible nice range of -20 to 19.
	#	              Before Linux 2.6, this was a scaled value based on the scheduler weighting given to this process.
	#  
	# 18: nice %ld    The nice value (see setpriority(2)), a value in the range 19 (low priority) to -20 (high priority).
	# 19: num_threads %ld  Number of threads in this process (since Linux 2.6).  Before kernel 2.6, this field was hard coded to 0 as a placeholder for an earlier removed field.
	# 20: itrealvalue %ld  The time in jiffies before the next SIGALRM is sent to the process due to an interval timer.  Since kernel 2.6.17, this field is no longer maintained, and is hard coded a
        # 21: starttime %llu (was %lu before Linux 2.6)  The time in jiffies the process started after system boot.
        # 22: vsize %lu   Virtual memory size in bytes.
        # 23: rss %ld     Resident Set Size: number of pages the process has in real memory.  This is just the pages which count toward text, data, or stack space.  This does not include pages which have not been demand-loaded  in,
        #                  or which are swapped out.
        # 24: rsslim %lu  Current soft limit in bytes on the rss of the process; see the description of RLIMIT_RSS in getpriority(2).
        # 25: startcode %lu  The address above which program text can run.
        # 26: endcode %lu The address below which program text can run.
        # 27: startstack %lu  The address of the start (i.e., bottom) of the stack.
        # 28: kstkesp %lu The current value of ESP (stack pointer), as found in the kernel stack page for the process.
        # 29: kstkeip %lu The current EIP (instruction pointer).
        # 30: signal %lu  The bitmap of pending signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
        # 31: blocked %lu The bitmap of blocked signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
        # 32: sigignore %lu The bitmap of ignored signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
        # 33: sigcatch %lu   The bitmap of caught signals, displayed as a decimal number.  Obsolete, because it does not provide information on real-time signals; use /proc/[pid]/status instead.
        # 34: wchan %lu   This  is the "channel" in which the process is waiting.  It is the address of a system call, and can be looked up in a namelist if you need a textual name.
        #                  (If you have an up-to-date /etc/psdatabase, then try ps -l to see the WCHAN field in action.)
        # 35: nswap %lu   Number of pages swapped (not maintained).
        # 36: cnswap %lu  Cumulative nswap for child processes (not maintained).
        # 37: exit_signal %d (since Linux 2.1.22)                          Signal to be sent to parent when we die.
        # 38: processor %d (since Linux 2.2.8)                          CPU number last executed on.
        # 39: rt_priority %u (since Linux 2.5.19; was %lu before Linux 2.6.22)                          Real-time scheduling priority, a number in the range 1 to 99 for processes scheduled under a real-time policy, or 0, for non-real-time processes (see sched_setscheduler(2)).
        # 40: policy %u (since Linux 2.5.19; was %lu before Linux 2.6.22)                          Scheduling policy (see sched_setscheduler(2)).  Decode using the SCHED_* constants in linux/sched.h.
        # 41: delayacct_blkio_ticks %llu (since Linux 2.6.18)                          Aggregated block I/O delays, measured in clock ticks (centiseconds).
        # 42: guest_time %lu (since Linux 2.6.24)                          Guest time of the process (time spent running a virtual CPU for a guest operating system), measured in clock ticks (divide by sysconf(_SC_CLK_TCK).
        # 43: cguest_time %ld (since Linux 2.6.24)                          Guest time of the process's children, measured in clock ticks (divide by sysconf(_SC_CLK_TCK).

	status = File.open("#{proc}/status") do |f|
	  res = {}
	  while f.gets =~ /([^:]+):\s+(.*)/	
	    res[$1] = $2.to_i
	  end
	  res
	end
	

			 
        # Required !
	result.ParentProcessID = stat[3]
	# Required !
	result.RealUserID = status["Uid"]
	# Required !
	result.ProcessGroupID = stat[4]
        result.ProcessSessionID = stat[5]
        result.ProcessTTY = stat[6]
        result.ModulePath = File.readlink("#{proc}/exe") rescue nil
	cmdline = File.read("#{proc}/cmdline").split(' ')
	cmdline.shift
        result.Parameters = cmdline
        result.ProcessNiceValue = stat[18]
        result.ProcessWaitingForEvent = nil # string  (-> CIM_UnixProcess)
        result.Name = stat[1]
        result.Priority = stat[17]
	result.ExecutionState = case stat[2]
          when "R" then ExecutionState.Running # R is running
          when "S" then ExecutionState.Ready # S is sleeping in an interruptible wait
          when "D" then ExecutionState.Blocked # D is waiting in uninterruptible disk sleep
          when "Z" then ExecutionState.Terminated # Z is zombie
          when "T" then ExecutionState.Stopped # T is traced or stopped (on a signal)
          when "W" then ExecutionState.send(:"Suspended Ready") # W is paging.
	  else
	    ExecutionState.Unknown
	  end
	starttime = stat[21].to_i # in jiffies after system boot
	uptime_in_secs = File.read('/proc/uptime').match(/^(\d+\.\d+) /)[1].to_i
	time = Time.new
        result.CreationDate = time - uptime_in_secs + starttime/4
      # result.TerminationDate = nil # dateTime  (-> CIM_Process)
        result.KernelModeTime = stat[14] # stat -> clock ticks, KernelModeTime -> ms
        result.UserModeTime = stat[13]
        result.WorkingSetSize = stat[23] # rss
      # result.EnabledState = EnabledState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.OtherEnabledState = nil # string  (-> CIM_EnabledLogicalElement)
      # result.RequestedState = RequestedState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.EnabledDefault = EnabledDefault.Enabled # uint16  (-> CIM_EnabledLogicalElement)
      # result.TimeOfLastStateChange = nil # dateTime  (-> CIM_EnabledLogicalElement)
      # result.AvailableRequestedStates = [AvailableRequestedStates.Enabled] # uint16[]  (-> CIM_EnabledLogicalElement)
      # result.TransitioningToState = TransitioningToState.Unknown # uint16  (-> CIM_EnabledLogicalElement)
      # result.InstallDate = nil # dateTime  (-> CIM_ManagedSystemElement)
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
    def invoke_method( context, result, reference, method, argsin, argsout )
      @trace_file.puts "invoke_method #{context}, #{result}, #{reference}, #{method}, #{argsin}, #{argsout}"
    end
    
    # Instance
    def create_instance( context, result, reference, newinst )
      @trace_file.puts "create_instance ref #{reference}, newinst #{newinst.inspect}"
      # RCP_UnixProcess.new reference, newinst
      # result.return_objectpath reference
      # result.done
      # true
    end

    def enum_instance_names( context, result, reference )
      @trace_file.puts "enum_instance_names ref #{reference}"
      each(context,reference) do |ref|
#        @trace_file.puts "RCP_UnixProcess.enum_instance_names => #{ref}"
        result.return_objectpath ref
      end
      result.done
      true
    end

    def enum_instances( context, result, reference, properties )
      @trace_file.puts "enum_instances ref #{reference}, props #{properties.inspect}"
      each(context,reference, properties, true) do |instance|
#        @trace_file.puts "RCP_UnixProcess.enum_instances => #{instance}"
        result.return_instance instance
      end
      result.done
      true
    end

    def get_instance( context, result, reference, properties )
      @trace_file.puts "get_instance ref #{reference}, props #{properties.inspect}"
      each(context,reference, properties, true) do |instance|
        @trace_file.puts "instance #{instance}"
        result.return_instance instance
        break # only return first instance
      end
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

    def cleanup( context, terminating )
      @trace_file.puts "cleanup terminating? #{terminating}"
      true
    end

    def self.typemap
      {
        "ParentProcessID" => Cmpi::string,
        "RealUserID" => Cmpi::uint64,
        "ProcessGroupID" => Cmpi::uint64,
        "ProcessSessionID" => Cmpi::uint64,
        "ProcessTTY" => Cmpi::string,
        "ModulePath" => Cmpi::string,
        "Parameters" => Cmpi::stringA,
        "ProcessNiceValue" => Cmpi::uint32,
        "ProcessWaitingForEvent" => Cmpi::string,
        "CSCreationClassName" => Cmpi::string,
        "CSName" => Cmpi::string,
        "OSCreationClassName" => Cmpi::string,
        "OSName" => Cmpi::string,
        "CreationClassName" => Cmpi::string,
        "Handle" => Cmpi::string,
        "Name" => Cmpi::string,
        "Priority" => Cmpi::uint32,
        "ExecutionState" => Cmpi::uint16,
        "OtherExecutionDescription" => Cmpi::string,
        "CreationDate" => Cmpi::dateTime,
        "TerminationDate" => Cmpi::dateTime,
        "KernelModeTime" => Cmpi::uint64,
        "UserModeTime" => Cmpi::uint64,
        "WorkingSetSize" => Cmpi::uint64,
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


    class ExecutionState < Cmpi::ValueMap
      def self.map
        {
          "Unknown" => 0,
          "Other" => 1,
          "Ready" => 2,
          "Running" => 3,
          "Blocked" => 4,
          "Suspended Blocked" => 5,
          "Suspended Ready" => 6,
          "Terminated" => 7,
          "Stopped" => 8,
          "Growing" => 9,
          "Ready But Relinquished Processor" => 10,
          "Hung" => 11,
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
