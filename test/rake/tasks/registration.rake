task :registration => [:prepstage] do |t|
  puts "Register all providers"
  
  require_relative "../test/registration"
  Dir['samples/registration/*.registration'].each do |regname|
    klass = File.basename regname, ".registration"
    register_klass :klass => klass
  end
  mkrepos
end
