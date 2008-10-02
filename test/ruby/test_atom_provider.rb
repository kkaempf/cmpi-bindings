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
    # create new instance -> check with .mof file
    def initialize broker
      super
    end
    
    # use i.e. 'include MethodProviderIF' to implement multiple MIs
    def create_instance context, result, reference, newinst
      STDERR.puts "TestAtomProvider.create_instance: #{reference}"
      result.return_objectpath reference
      result.done
    end
    
    def get_instance context, result, objname, plist
      
      plist = plist.join(',') if plist.respond_to? :join

      STDERR.puts "TestAtomProvider.get_instance: #{objname}: #{plist}"
    end
    
    def delete_instance context, result, objname
      STDERR.puts "TestAtomProvider.delete_instance: #{objname}"
    end
  
  end

end
