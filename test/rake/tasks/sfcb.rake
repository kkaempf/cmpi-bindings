task :sfcb => ["tmp/sfcb/sfcb.cfg", :registration] do
  $sfcb.start
end
