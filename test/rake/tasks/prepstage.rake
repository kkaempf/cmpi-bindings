directory "tmp"
directory "tmp/sfcb"

file "tmp/sfcb/sfcb.cfg" => ["tmp/sfcb", :mksfcb] do
  $sfcb.mkcfg
end

task :mksfcb do
  require_relative "../test/helper"
  Helper.sfcb
end

task :prepstage => ["tmp/sfcb/sfcb.cfg"] do
  puts "Prepare sfcb staging"
end