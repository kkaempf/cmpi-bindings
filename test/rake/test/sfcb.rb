#
# Start and stop sfcb for testing
#
require 'tmpdir'
require 'uri'

require_relative "./env"

class Sfcb
  attr_reader :pid, :uri, :dir, :stage_dir, :registration_dir, :providers_dir

  def initialize args = {}
    @execfile = "/usr/sbin/sfcbd"
    @port = 12345
    @pid = nil

    tmpdir = args[:tmpdir] || Dir.tmpdir

    File.directory?(tmpdir) || Dir.mkdir(tmpdir)

    @dir = File.join(tmpdir, "sfcb")
    Dir.mkdir @dir rescue nil

#    STDERR.puts "Sfcb directory at #{@dir}"

    # location of cmpi-bindings for Ruby
    @providers_dir = File.expand_path(File.join(TOPLEVEL,"..","..","build","swig","ruby"))

    @stage_dir = File.join(dir, "stage")
    Dir.mkdir @stage_dir rescue nil
    File.symlink("/var/lib/sfcb/stage/default.reg", File.join(@stage_dir, "default.reg")) rescue nil
    @mofs_dir = args[:mof] || File.join(@stage_dir, "mofs")
    Dir.mkdir @mofs_dir rescue nil
  
    @registration_dir = args[:registration] || File.join(dir, "registration")
    Dir.mkdir @registration_dir rescue nil

#    Kernel.system "sfcbrepos", "-s", @stage_dir, "-r", @registration_dir, "-f"
  
    @uri = URI::HTTP.build :host => 'localhost', :port => @port, :userinfo => "wsman:secret"
  end

  def mkcfg
    @cfgfile = File.join(@dir, "sfcb.cfg")
    File.open(@cfgfile, "w+") do |f|
      # create sfcb config file

      {
	"enableHttp" => true,
	"httpPort" => @port,
	"enableHttps" => false,
	"enableSlp" => false,
	"providerTimeoutInterval" => 10,
        "keepaliveTimeout" => 2,
	"registrationDir" => @registration_dir,
	"localSocketPath" => File.join(@dir, "sfcbLocalSocket"),
	"httpSocketPath" => File.join(@dir, "sfcbHttpSocket"),
	"providerDirs" => " #{@providers_dir} /usr/lib64/sfcb /usr/lib/sfcb /usr/lib64 /usr/lib /usr/lib64/cmpi /usr/lib/cmpi"
      }.each do |k,v|
	f.puts "#{k}: #{v}"
      end
    end
  end

  def start
    raise "Already running" if @pid
    @pid = fork
    if @pid.nil?
      # child
      sfcb_trace_file = File.join(TMPDIR, "sfcb_trace_file")
      sblim_trace_file = File.join(TMPDIR, "sblim_trace_file")
      ruby_providers_dir = File.expand_path(File.join(TOPLEVEL,"samples","provider"))
      Dir.chdir File.expand_path("..", File.dirname(__FILE__))
      {
	"SFCB_TRACE_FILE" => sfcb_trace_file,
        "SFCB_TRACE" => "4",
        "SBLIM_TRACE_FILE" => sblim_trace_file,
        "SBLIM_TRACE" => "4",
#        "CMPISFCC_DEBUG" => "true",
        "RUBY_PROVIDERS_DIR" => ruby_providers_dir
      }.each do |k,v|
        ENV[k] = v
      end
      File.delete(sfcb_trace_file) rescue nil
      File.delete(sblim_trace_file) rescue nil
      $stderr.reopen(File.join(TMPDIR, "sfcbd.err"), "w")
      $stdout.reopen(File.join(TMPDIR, "sfcbd.out"), "w")
      Kernel.exec "#{@execfile}", "-t", "8", "-c", "#{@cfgfile}"#, "-t", "32768"
    end
    @pid
  end

  def stop
    return unless @pid
    Process.kill "QUIT", @pid
    sleep 3
    Process.wait
    @pid = nil
  end
end
