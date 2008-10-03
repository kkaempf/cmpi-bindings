# Model an atom, For use with CIMOM and Ruby provider
#
#    INTRINSIC DATA TYPE INTERPRETATION
#    uint8 Unsigned 8-bit integer
#    sint8 Signed 8-bit integer
#    uint16 Unsigned 16-bit integer
#    sint16 Signed 16-bit integer
#    uint32 Unsigned 32-bit integer
#    sint32 Signed 32-bit integer
#    uint64 Unsigned 64-bit integer
#    sint64 Signed 64-bit integer
#    string UCS-2 string
#    boolean Boolean
#    real32 IEEE 4-byte floating-point
#    real64 IEEE 8-byte floating-point
#    datetime A string containing a date-time
#    <classname> ref Strongly typed reference
#    char16 16-bit UCS-2 character
#

class Test_Atom
  attr_accessor :uint8Prop, :uint8Propa, :sint8prop, :sint8propa
  attr_accessor :uint16Prop, :uint16Propa, :sint16prop, :sint16propa
  attr_accessor :uint32Prop, :uint32Propa, :sint32prop, :sint32propa
  attr_accessor :uint64Prop, :uint64Propa, :sint64prop, :sint64propa
  attr_accessor :stringProp, :stringPropa
  attr_accessor :real32Prop, :real32Propa, :real64Prop, :real64Propa
  attr_accessor :dateProp, :boolProp
  
  def initialize name
    @uint8Prop = @sint8prop = @uint16Prop = @sint16prop = 0
    @uint8Propa = @sint8propa = @uint16Propa = @sint16propa = []
    @uint32Prop = @sint32prop = @uint64Prop = @sint64prop = 0
    @uint32Propa = @sint32propa = @uint64Propa = @sint64propa = []
    @stringProp = ""
    @stringPropa = []
    @real32prop = @real64prop = 0.0
    @real32propa = @real64Propa = []
    @dateProb = Time.new
    @boolProb = false
    @name = name
  end

end
