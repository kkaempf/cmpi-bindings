#
# extconf.rb for cmpi-bindings Gem
#

require 'mkmf'
# $CFLAGS = "#{$CFLAGS} -Werror"

# requires sblim-cmpi-devel or tog-pegasus-devel

find_header 'cmpidt.h', '/usr/include/cmpi', '/usr/include/Pegasus/Provider/CMPI'

$CPPFLAGS = "-I/usr/include/cmpi -I/usr/include/Pegasus/Provider/CMPI -I.."

create_makefile('cmpi-bindings')
