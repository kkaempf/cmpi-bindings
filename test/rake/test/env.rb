#
# test/env.rb
#

fdirname = File.dirname(__FILE__)

##
# Assuming __FILE__ lives in test/
#

# establish parent for test data
TOPLEVEL = File.expand_path(File.join(fdirname,".."))

NAMESPACE = "test/test"

TMPDIR = File.join(TOPLEVEL, "tmp")

