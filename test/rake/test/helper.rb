#
# test/helper.rb
#

require_relative "./env"
require_relative "./sfcb"

class Helper
  def self.sfcb
    $sfcb ||= Sfcb.new :tmpdir => TMPDIR, :provider => "#{TOPLEVEL}/samples/provider"
  end
  def self.setup klass, namespace = "test/test"
    self.sfcb
    client = Sfcc::Cim::Client.connect(:uri => $sfcb.uri, :verify => false)
    raise "Connection error" unless client
    op = Sfcc::Cim::ObjectPath.new(namespace, klass, client)
    return client, op
  end
  def self.teardown
    $sfcb.stop
  end
end

