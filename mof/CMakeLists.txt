#
#
#
SET( CMPI_MOF_DIR /var/lib/sfcb/stage/mofs )
SET( CMPI_REG_DIR /var/lib/sfcb/stage/regs )

INSTALL(FILES Swig_Generic.mof DESTINATION ${CMPI_MOF_DIR}/root/cimv2)
INSTALL(FILES Py_UnixProcess.mof DESTINATION ${CMPI_MOF_DIR}/root/cimv2)
INSTALL(FILES Swig_Generic.reg DESTINATION ${CMPI_REG_DIR})
INSTALL(FILES Py_UnixProcess.reg DESTINATION ${CMPI_REG_DIR})
INSTALL(CODE "MESSAGE(\"Now run 'sfcbrepos -f'.\")")
#INSTALL(SCRIPT "sfcbrepos -f")

