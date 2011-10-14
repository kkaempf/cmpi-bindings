#
# cmpi.rb
#
# Main entry point for cmpi-bindings-ruby, Ruby based CIM Providers
#

class String
  #
  # Convert from CamelCase to under_score
  #
  def decamelize
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
	 gsub(/([a-z\d])([A-Z])/,'\1_\2').
	 tr("-", "_").
	 downcase
  end
end

#
# = Cmpi - Common Manageablity Programming Interface
#
# The Common Manageablity Programming Interface (CMPI) defines a common standard of interfacing Manageability Instrumentation (providers, instrumentation) to Management Brokers (CIM Object Manager). The purpose of CMPI is to standardize Manageability Instrumentation. This allows to write and build instrumentation once and run it in different CIM environments (on one platform).
#
# == CIMOM Context
#
# == Provider Interface
#

module Cmpi

  def self.null
    0
  end
  def self.boolean
    (2+0)
  end
  def self.char16
    (2+1)
  end

  def self.real32
    ((2+0)<<2)
  end
  def self.real64
    ((2+1)<<2)
  end

  def self.uint8
    ((8+0)<<4)
  end
  def self.uint16
    ((8+1)<<4)
  end
  def self.uint32
    ((8+2)<<4)
  end
  def self.uint64
    ((8+3)<<4)
  end
  def self.SINT
    ((8+4)<<4)
  end
  def self.sint8
    ((8+4)<<4)
  end
  def self.sint16
    ((8+5)<<4)
  end
  def self.sint32
    ((8+6)<<4)
  end
  def self.sint64
    ((8+7)<<4)
  end
  def self.instance
    ((16+0)<<8)
  end
  def self.ref
    ((16+1)<<8)
  end
  def self.args
    ((16+2)<<8)
  end
  def self.class
    ((16+3)<<8)
  end
  def self.filter
    ((16+4)<<8)
  end
  def self.enumeration
    ((16+5)<<8)
  end
  def self.string
    ((16+6)<<8)
  end
  def self.chars
    ((16+7)<<8)
  end
  def self.dateTime
    ((16+8)<<8)
  end
  def self.ptr
    ((16+9)<<8)
  end
  def self.charsptr
    ((16+10)<<8)
  end
  
  #
  # Base class for ValueMap/Values classes from genprovider
  #
  class ValueMap
    def self.method_missing name, *args
      t = self.type
      v = self.map[name.to_s]
      return [v,t] if v
      STDERR.puts "#{self.class}.#{name} ?"
      nil
    end
  end
  #
  # CMPIContext gives the context for Provider operation
  #
  class CMPIContext
    def count
      #can't use alias here because CMPIContext::get_entry_count is only defined after
      # initializing the provider (swig init code)
      get_entry_count
    end
    def [] at
      if at.kind_of? Integer
	get_entry_at( at )
      else
	get_entry( at.to_s )
      end
    end
    def each
      0.upto(self.count-1) do |i|
	yield get_entry_at(i)
      end
    end
  end
  
  #
  # CMPIInstance
  #
  class CMPIInstance
    def each
      (0..self.size-1).each do |i|
	yield self.get_property_at(i)
      end
    end
    def to_s
      s = ""
      self.each do |value,name|
	next unless value
	s << ", " unless s.empty?
	s << "\"#{name}\" => #{value.inspect}"
      end
      s = "#{self.class}(" + s + ")"
    end
  end
  
  #
  # CMPIObjectPath
  #
  class CMPIObjectPath
    #
    # Allow Ref.Property and Ref.Property=
    #
    def method_missing name, *args
      s = name.to_s
      if s =~ /=$/
	v,t = args[0]
#	STDERR.puts "CMPIObjectPath.#{name} = #{v.inspect}<#{t}>"
        self[s.chop,v] = t
      else
#	STDERR.puts "CMPIObjectPath.#{name} -> #{self[s].inspect}"
	self[s]
      end
    end
  end
end
