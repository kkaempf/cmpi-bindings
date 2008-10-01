#
# Ruby Provider for TestAtom
#
# Instruments the CIM class TestAtom
#

module Cmpi
  
  STDERR.puts "This is test_atom_provider.rb"
  # Instrument the CIM class TestAtom 
  #
  # Model an atom, For use with CIMOM and RbWbem Provider
  #    

  class TestAtomProvider
    STDERR.puts "This is TestAtomProvider within test_atom_provider.rb"

    def initialize broker
      STDERR.puts "TestAtomProvider initialized!"
      @broker = broker
    end
    
    def create_instance context, result, reference, newinst
      STDERR.puts "TestAtomProvider.create_instance"
    end
  end

end