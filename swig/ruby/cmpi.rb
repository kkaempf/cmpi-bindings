#
# cmpi.rb
#
# Main entry point for cmpi-bindings-ruby, Ruby based CIM Providers
#

class String
  def decamelize
    # CamelCase -> under_score
    self.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
	 gsub(/([a-z\d])([A-Z])/,'\1_\2').
	 tr("-", "_").
	 downcase
  end
end

module Cmpi
  # init
  
  #
  # on-demand loading of Ruby providers
  # create provider for 'miname'
  #  pass 'broker' to its constructor
  #
  def self.create_provider miname, broker, context

    context.each do |name,value|
      STDERR.puts "Context '#{name}' = #{value}"
    end

    begin
      # Expect provider below cmpi/providers
      require File.join(File.dirname(__FILE__),"cmpi","providers",miname.decamelize) # add to load path
    rescue Exception
      STDERR.puts "Loading provider #{miname.decamelize}.rb for provider #{miname} failed: #{$!.message}"
      raise
    end

    Cmpi.const_get(miname).new broker
  end

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
end
