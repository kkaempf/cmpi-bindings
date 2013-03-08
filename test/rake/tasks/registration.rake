task :sfcb_registration => [:sfcb_configuration] do |t|
  puts "Register all providers"
  
  require_relative "../test/registration"
  Dir['samples/registration/*.registration'].each do |regname|
    klass = File.basename regname, ".registration"
    register_klass :klass => klass
  end
  mkrepos
end


task :pegasus_registration => [:pegasus_configuration] do
  puts "Registering Pegasus providers"
end
