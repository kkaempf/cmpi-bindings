#
# test/helper.rb
#

require_relative "./env"

class Helper
  
  # called from rake

  def self.cimom= name
    @@cimom ||= case name
    when :sfcb
      require_relative "./sfcb"
      Sfcb.new :tmpdir => TMPDIR, :provider => "#{TOPLEVEL}/samples/provider"
    when :pegasus
      require_relative "./pegasus"
      Pegasus.new :tmpdir => TMPDIR, :provider => "#{TOPLEVEL}/samples/provider"
    else
      raise "Unknown CIMOM #{@cimom}"
    end
  end
  def self.cimom
    @@cimom rescue (self.cimom = :sfcb; @@cimom)
  end
  
  # called from test/unit
  
  def self.setup klass, namespace = "test/test"
    client = Sfcc::Cim::Client.connect(:uri => self.cimom.uri, :verify => false)
    raise "Connection error" unless client
    op = Sfcc::Cim::ObjectPath.new(namespace, klass, client)
    return client, op
  end
  def self.teardown
    self.cimom.stop
  end
end
