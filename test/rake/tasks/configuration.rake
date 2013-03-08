directory "tmp"
directory "tmp/sfcb" => ["tmp"]

file "tmp/sfcb/sfcb.cfg" => ["tmp/sfcb"] do
  Helper.cimom.mkcfg
end

task :sfcb_configuration => ["tmp/sfcb/sfcb.cfg"]


task :pegasus_configuration do
  Helper.cimom.mkcfg
end
