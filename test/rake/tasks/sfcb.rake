require_relative "../test/helper"

task :cimom_is_sfcb do
  Helper.cimom = :sfcb
end

task :sfcb => [:cimom_is_sfcb, :sfcb_configuration, :sfcb_registration] do
  Helper.cimom.start
end
