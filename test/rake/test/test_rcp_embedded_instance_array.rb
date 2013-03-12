#
# Testcase for test/test:RCP_EmbeddedInstanceArray
#
require 'rubygems'
require 'sfcc'
require 'test/unit'
require_relative "./helper"

class Test_RCP_EmbeddedInstanceArray < Test::Unit::TestCase
  def setup
    @client, @op = Helper.setup 'RCP_EmbeddedInstanceArray'
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
      assert_kind_of Array, embedded
      assert_equal 3, embedded.size
      i = 0
      embedded.each do |inst|
        i += 1
        assert_kind_of Sfcc::Cim::Instance, inst # string
        assert inst.classname
        assert_equal "CIM_ManagedElement", inst.classname
        assert inst.InstanceID
        assert_kind_of String, inst.InstanceID
        assert inst.Caption
        assert_kind_of String, inst.Caption
        assert inst.Description
        assert_kind_of String, inst.Description
        assert inst.ElementName
        assert_kind_of String, inst.ElementName
        assert inst.Generation
        assert_kind_of Integer, inst.Generation
        assert_equal i, inst.Generation
      end
    end
  end

end
