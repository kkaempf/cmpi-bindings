#
# Start and stop Pegasus for testing
#
require 'tmpdir'
require 'uri'

require_relative "./env"

class Pegasus
  attr_reader :pid, :uri, :dir, :stage_dir, :registration_dir, :providers_dir
private
  def getconfig name
    result = nil
    pipe = IO.popen "sudo cimconfig -g #{name}"
    unless pipe
      system "sudo cimserver"
      pipe = IO.popen "sudo cimconfig -g #{name}"
    end
    if pipe.read =~ /^Current value:\s+(.*)$/
      result = $1
    end
    pipe.close
    result
  end
  def setconfig name, value
    puts "Setting #{name} to '#{value}'"
    system "sudo cimconfig -p -s '#{name}=#{value}'"
  end
public
  
  def initialize args = {}
    @execfile = "/usr/sbin/cimserver"
    @port = 12345
    @pid = nil
    @config = {}

    tmpdir = args[:tmpdir] || Dir.tmpdir

    File.directory?(tmpdir) || Dir.mkdir(tmpdir)

    @dir = File.join(tmpdir, "pegasus")
    Dir.mkdir @dir rescue nil

    STDERR.puts "Pegasus directory at #{@dir}"

    # location of cmpi-bindings for Ruby
    @providers_dir = File.expand_path(File.join(TOPLEVEL,"..","..","build","swig","ruby"))

    # location of cmpi-bindings for Python
    @providers_dir = File.expand_path(File.join(TOPLEVEL,"..","..","build","swig","python"))

  
  end

  def uri
    unless @uri
      if getconfig("enableHttpConnection") == "true"
        scheme = "http"
        port = getconfig("httpPort") || 5988
      elsif getconfig("enableHttpsConnection") == "true"
        scheme = "https"
        port = getconfig("httpsPort") || 5989
      else
        raise "No enabled connection"
      end
      # scheme, userinfo, host, port, registry, path, opaque, query and fragment, 
      @uri = URI::HTTP.new scheme, "wsman:secret", "localhost", port
    end
    @uri
  end

  def mkcfg
#    trace_components = [ALL
#    AsyncOpNode
#    Authentication
#    Authorization
#    BinaryMessageHandler
#    Channel
#    CimData
#    CIMExportRequestDispatcher
#    CIMOMHandle
#    Config
#    ConfigurationManager
#    ControlProvider
#    CQL
#    DiscardedData
#    Dispatcher
#    ExportClient
#    Http
#    IndDelivery
#    IndicationHandlerService
#    IndicationService
#    IndicationServiceInternal
#    IndHandler
#    IPC
#    L10N
#    Listener
#    Memory
#    MessageQueueService
#    MetaDispatcher
#    ObjectResolution
#    OsAbstraction
#    ProviderAgent
#    ProviderManager
#    ProvManager
#    Registration
#    Repository
#    Server
#    Shutdown
#    SubscriptionService
#    Thread
#    UserManager
#    WQL
#    XmlIO
#    XmlParser
#    XmlReader
#    XmlWriter
    @config = {
      "daemon" => "false",
      "enableAuthentication" => "false",
      "enableHttpConnection" => "true",
      "enableHttpsConnection" => "false",
      "httpPort" => @port,
      "traceFilePath" => File.join(@dir, "trace.log"),
      "traceLevel" => 1, # 1,2,3,4
#      "traceComponents" => "",
#      "logLevel" => "INFORMATION", # TRACE, INFORMATION, WARNING, SEVERE, FATAL.
#      "repositoryDir" => "/var/lib/Pegasus/repository",
      "providerDir" => "#{@providers_dir}:/usr/lib64/cmpi:/usr/lib/cmpi:/usr/lib64/pycim:/usr/lib/pycim:/usr/lib64/Pegasus/providers:/usr/lib/Pegasus/providers"
    }
  end

  def start
    unless system "sudo #{@execfile} --status"
      cmd = ["sudo", @execfile] + @config.collect{ |k,v| "#{k}=#{v}" }
      puts cmd.inspect
      system *cmd
    end
  end

  def stop
    system "sudo #{@execfile} -s"
  end
end
