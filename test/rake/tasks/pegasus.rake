require_relative "../test/helper"

task :cimom_is_pegasus do
  Helper.cimom = :pegasus
end

task :pegasus => [:cimom_is_pegasus, :pegasus_configuration, :pegasus_registration] do
  Helper.cimom.start
end
