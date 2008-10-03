#
# Ruby Provider for TestAtom
#
# Instruments the CIM class Test_Atom
#

module Cmpi

  STDERR.puts "This is test_atom_provider.rb"
  # Instrument the CIM class TestAtom 
  #
  # Model an atom, For use with CIMOM and RbWbem Provider
  #    

  class TestAtomProvider < InstanceProvider
    require 'Test_Atom'

    # create new provider instance -> check with .mof file
    def initialize broker
      @instances = {}
      super
    end
    
    # use i.e. 'include MethodProviderIF' to implement multiple MIs
    def create_instance context, result, reference, newinst
      STDERR.puts "TestAtomProvider.create_instance: #{reference}"
      STDERR.puts "TestAtomProvider.create_instance: #{reference.key_count} keys"
      reference.keys do |value,name|
	STDERR.puts "Key #{name} = #{value}"
      end
      @instances[reference.to_s] = Test_Atom.new reference.get_key_at(0)[0]._value
      result.return_objectpath reference
      result.done
    end
    
    def get_instance context, result, objname, plist
      
      plist = plist.join(',') if plist.respond_to? :join

      STDERR.puts "TestAtomProvider.get_instance: #{objname}: #{plist}"
      instance = @instances[objname]
      result.return_instance instance if instance
      result.done
    end
    
    def delete_instance context, result, objname
      STDERR.puts "TestAtomProvider.delete_instance: #{objname}"
      @instances.delete objname
    end
  
  end

end
