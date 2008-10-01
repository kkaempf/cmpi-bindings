#
# Module RbCmpi
#
# Main entry point for cmpi-bindings-ruby, Ruby based CIM Providers
#

module Cmpi
  STDERR.puts "Hello from cmpi-bindings-ruby"
  # init
  RBCIMPATH = "/usr/lib/rbcim/"
  
  # look for .rb files below RBCIMPATH
  # and load them
  if File.directory?(RBCIMPATH) then
    $:.unshift RBCIMPATH # add to load path
    STDERR.puts "Looking into #{RBCIMPATH}"
    Dir.foreach( RBCIMPATH ) do |entry|
      STDERR.puts "Found #{entry}"
      split = entry.split '.'
      if split[1] == 'rb' then
	begin
	  STDERR.puts "Loading #{split[0]}"
	  require split[0]
	rescue Exception => e
	  STDERR.puts "Loading #{split[0]} failed: #{e}"
	end
      end
    end
    $:.shift # take load path away
  end
end
