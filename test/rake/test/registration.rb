require_relative "./env"
require_relative "./mkreg"
require_relative "./sfcb"

#
# register
#   args: Hash
#     :klass => CIM class name
#     :namespace => namespace, defaults to test/test
#     :mofdir => where to find <klass>.mof, defaults to TOPLEVEL/samples/mof
#     :regdir => where to find <klass>.registration, defaults to TOPLEVEL/samples/registration
#

def register_klass args
  args[:mofdir] ||= File.join(TOPLEVEL, "samples", "mof")
  args[:regdir] ||= File.join(TOPLEVEL, "samples", "registration")
  args[:namespace] ||= "test/test"
  klass = args[:klass]
  raise "No :klass passed to registration" unless klass
  tmpregname = File.join(TMPDIR, "#{klass}.reg")

  # convert generic <klass>.registration to sfcb-specific <klass>.reg
  convert_registrations tmpregname, File.join(args[:regdir], "#{klass}.registration")

  # stage .reg+.mof to namespace
  cmd = "sfcbstage -s #{$sfcb.stage_dir} -n #{args[:namespace]} -r #{tmpregname} #{File.join(args[:mofdir],args[:klass])}.mof"
#  STDERR.puts cmd
  res = `#{cmd} 2> #{TMPDIR}/sfcbstage.err`
  raise "Failed: #{cmd}" unless $? == 0
end

def mkrepos
  cmd = "sfcbrepos -f -s #{$sfcb.stage_dir} -r #{$sfcb.registration_dir}"
#  STDERR.puts cmd
  res = `#{cmd} 2> #{TMPDIR}/sfcbrepos.err`
  raise "Failed: #{cmd}" unless $? == 0
end
