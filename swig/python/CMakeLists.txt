#
# CMakeLists.txt for cmpi-bindings/swig/ruby
#

enable_testing()
add_subdirectory(tests)

SET (BUILD_SHARED_LIBS ON)

FIND_PACKAGE(PythonInterp REQUIRED)

EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c "from sys import stdout; from distutils import sysconfig; stdout.write(sysconfig.get_python_lib())" OUTPUT_VARIABLE PYTHON_LIB_DIR)

IF (NOT PYTHON_SITE_DIR)
  SET (PYTHON_SITE_DIR ${PYTHON_LIB_DIR})
ENDIF (NOT PYTHON_SITE_DIR)

MESSAGE(STATUS "Python executable: ${PYTHON_EXECUTABLE}")
MESSAGE(STATUS "Python inc dir: ${PYTHON_INCLUDE_PATH}")
MESSAGE(STATUS "Python lib dir: ${PYTHON_LIB_DIR}")
#MESSAGE(STATUS "Python libraries: ${PYTHON_LIBRARIES}")
MESSAGE(STATUS "Python site dir: ${PYTHON_SITE_DIR}")

SET( SWIG_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cmpi_wrap.c" )
SET( SWIG_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/../cmpi.i" )

ADD_CUSTOM_COMMAND (
   OUTPUT  ${SWIG_OUTPUT}
   COMMAND ${CMAKE_COMMAND} -E echo_append "Creating wrapper code for Python ..."
   COMMAND ${SWIG_EXECUTABLE} -python -threads -features autodoc -o ${SWIG_OUTPUT} -outdir ${CMAKE_CURRENT_BINARY_DIR} -I${CMPI_INCLUDE_DIR} ${SWIG_INPUT}
   COMMAND ${CMAKE_COMMAND} -E echo "Done."
   WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.i
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../../src/*.c
)

SET( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -g" )

INCLUDE_DIRECTORIES( ${CMAKE_CURRENT_SOURCE_DIR}/.. )
INCLUDE_DIRECTORIES( ${PYTHON_INCLUDE_PATH} )
INCLUDE_DIRECTORIES( ${CMPI_INCLUDE_DIR} )

ADD_DEFINITIONS(-DCMPI_PLATFORM_LINUX_GENERIC_GNU -DCMPI_VERSION=200)

#
# cmpi_provider: provider .so
#

SET( NAME pyCmpiProvider )
ADD_LIBRARY( ${NAME} SHARED ${SWIG_OUTPUT})
#TARGET_LINK_LIBRARIES( ${NAME} ${PYTHON_LIBRARIES} )
TARGET_LINK_LIBRARIES( ${NAME} python${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION} )
TARGET_LINK_LIBRARIES( ${NAME} pthread )
TARGET_LINK_LIBRARIES( ${NAME} dl )
TARGET_LINK_LIBRARIES( ${NAME} util )

INSTALL(TARGETS ${NAME} LIBRARY DESTINATION ${CMPI_LIBRARY_DIR})
# .py: swig generated
INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/cmpi.py DESTINATION ${PYTHON_SITE_DIR} )


#
# cmpi_pywbem_bindings.py: provider implementation
#
INSTALL(FILES cmpi_pywbem_bindings.py DESTINATION ${PYTHON_SITE_DIR} )
#INSTALL(FILES Py_UnixProcessProvider.py DESTINATION /usr/lib/pycim )

INSTALL(CODE "EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c \"from py_compile import compile; compile('\$ENV{DESTDIR}${PYTHON_SITE_DIR}/cmpi.py', dfile='${PYTHON_SITE_DIR}/cmpi.py')\")")

INSTALL(CODE "EXECUTE_PROCESS(COMMAND ${PYTHON_EXECUTABLE} -c \"from py_compile import compile; compile('\$ENV{DESTDIR}${PYTHON_SITE_DIR}/cmpi_pywbem_bindings.py', dfile='${PYTHON_SITE_DIR}/cmpi_pywbem_bindings.py')\")")





