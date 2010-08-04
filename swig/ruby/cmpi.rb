#
# cmpi.rb
#
# Main entry point for cmpi-bindings-ruby, Ruby based CIM Providers
#

module Cmpi
  # init
  
  #
  # on-demand loading of Ruby providers
  # create provider for 'classname'
  #  pass 'broker' to its constructor
  #
  def self.create_provider classname, broker, context

    context.each do |name,value|
      STDERR.puts "Context '#{name}' = #{value}"
    end
    # CamelCase -> under_score
    underscore = classname.
	           gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
		   gsub(/([a-z\d])([A-Z])/,'\1_\2').
		   tr("-", "_").
		   downcase

    begin
      # Expect provider below cmpi/providers
      require File.join(File.dirname(__FILE__),"cmpi","providers",underscore) # add to load path
    rescue Exception
      STDERR.puts "Loading provider #{underscore}.rb for class #{classname} failed: #{$!.message}"
      raise
    end

    Cmpi.const_get(classname).new broker
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
