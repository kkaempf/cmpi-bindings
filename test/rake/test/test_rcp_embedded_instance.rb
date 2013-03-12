#
# Testcase for test/test:RCP_EmbeddedInstance
#
require 'rubygems'
require 'sfcc'
require 'test/unit'
require_relative "./helper"

class Test_RCP_EmbeddedInstance < Test::Unit::TestCase
  def setup
    @client, @op = Helper.setup 'RCP_EmbeddedInstance'
    assert @op.client
    assert_equal @client, @op.client
  end
  
  def teardown
    Helper.teardown
  end

  def test_registered
    cimclass = @client.get_class(@op)
    assert cimclass
  end
  
  def test_instances
    instances = @client.instances(@op)
    assert instances.size > 0
    instances.each do |instance|
      puts "Instance #{instance}"
      assert instance
      puts "instance.InstanceID #{instance.InstanceID.inspect}"
      assert instance.InstanceID
      assert_kind_of String, instance.InstanceID # string
      embedded = instance.EmbeddedInstance
      puts "instance.EmbeddedInstance #{embedded.inspect}"
      assert embedded
      assert_kind_of Sfcc::Cim::Instance, embedded # string
      assert embedded.classname
      assert_equal "CIM_ManagedElement", embedded.classname
      assert embedded.InstanceID
      assert_kind_of String, embedded.InstanceID
      assert embedded.Caption
      assert_kind_of String, embedded.Caption
      assert embedded.Description
      assert_kind_of String, embedded.Description
      assert embedded.ElementName
      assert_kind_of String, embedded.ElementName
      assert embedded.Generation
      assert_kind_of Integer, embedded.Generation
    end
  end

end
