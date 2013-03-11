#
# Testcase for test/test:LMI_Embedded
#
require 'rubygems'
require 'sfcc'
require 'test/unit'
require_relative "./helper"

class Test_LMI_Embedded < Test::Unit::TestCase
  def setup
    @client, @op = Helper.setup 'LMI_Embedded'
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
  
  def xtest_instance_names
    names = @client.instance_names(@op)
    assert names.size > 0
    names.each do |ref|
      puts "ref #{ref}"
      ref.namespace = @op.namespace
      instance = @client.get_instance ref
      assert instance
      puts "Instance #{instance}"
      assert instance.InstanceID
      assert_kind_of String, instance.InstanceID # string
      puts "instance.InstanceID #{instance.InstanceID.inspect}"
      assert instance.Embedded
      assert_kind_of String, instance.Embedded # string
      puts "instance.Embedded #{instance.Embedded.inspect}"
      assert instance.Str
      assert_kind_of String, instance.Str # string
      puts "instance.Str #{instance.Str.inspect}"
    end
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
      puts "instance.Str #{instance.Str.inspect}"
      assert instance.Str
      assert_kind_of String, instance.Str # string
      embedded = instance.Embedded
      puts "instance.Embedded #{instance.Embedded.inspect}"
      assert embedded
      assert_kind_of Sfcc::Cim::Instance, embedded # string
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
