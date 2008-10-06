#
# CMakeLists.txt for cmpi-bindings
#
PROJECT(cmpi-bindings)

cmake_minimum_required(VERSION 2.4)

include(CTest)
enable_testing()
#
# cmake2.6: backward compatibility to cmake 2.4
#
if(COMMAND cmake_policy)
  cmake_policy(SET CMP0003 OLD)
endif(COMMAND cmake_policy)
	      
# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ is checked
SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules ${CMAKE_MODULE_PATH})
#SET(CMAKE_MODULE_PATH ${CMAKE_INSTALL_PREFIX}/share/cmake/Modules ${CMAKE_MODULE_PATH})

# Library
IF ( DEFINED LIB )
  SET ( CMPI_LIBRARY_DIR "${CMAKE_INSTALL_PREFIX}/${LIB}/cmpi" )
ELSE ( DEFINED  LIB )
  IF (CMAKE_SIZEOF_VOID_P MATCHES "8")
    SET( LIB_SUFFIX "64" )
  ENDIF(CMAKE_SIZEOF_VOID_P MATCHES "8")
  SET ( CMPI_LIBRARY_DIR "${CMAKE_INSTALL_PREFIX}/lib${LIB_SUFFIX}/cmpi" )
ENDIF ( DEFINED  LIB )
MESSAGE(STATUS "Providers will be installed in ${CMPI_LIBRARY_DIR}" )

# Include
SET( CMPI_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/include/cmpi )



INCLUDE(${CMAKE_SOURCE_DIR}/VERSION.cmake)

SET(CMAKE_VERBOSE_MAKEFILE TRUE)
SET( PACKAGE "cmpi-bindings" )
SET( VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}" )


####################################################################
# CPACK                                                            #
####################################################################


SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Language Bindings for CMPI")
SET(CPACK_PACKAGE_VENDOR "Novell Inc.")
SET(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/doc/README")
SET(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.BSD")
SET(CPACK_PACKAGE_VERSION_MAJOR ${VERSION_MAJOR})
SET(CPACK_PACKAGE_VERSION_MINOR ${VERSION_MINOR})
SET(CPACK_PACKAGE_VERSION_PATCH ${VERSION_PATCH})

SET( CPACK_GENERATOR "TBZ2")
SET( CPACK_SOURCE_GENERATOR "TBZ2")
SET( CPACK_SOURCE_PACKAGE_FILE_NAME "${PACKAGE}-${VERSION}" )

# The following components are regex's to match anywhere (unless anchored)
# in absolute path + filename to find files or directories to be excluded
# from source tarball.
SET (CPACK_SOURCE_IGNORE_FILES
"/CVS/;/.svn/;/.libs/;/.deps/;.swp$;.#;/#;/build/"
"~$"
"\\\\.cvsignore$"
"Makefile\\\\.in$"
)

INCLUDE(CPack)

####################################################################
# Find SWIG                                                        #
####################################################################

FIND_PACKAGE(SWIG)
IF( NOT SWIG_EXECUTABLE)
  MESSAGE(STATUS "Looking modules in ${CMAKE_MODULE_PATH}")
  FIND_PROGRAM(SWIG_EXECUTABLE
    NAMES swig-1.3 swig
    PATHS ${SWIG_DIR} ${SWIG_DIR}/.. ${SWIG_DIR}/../../bin /usr/bin /usr/local/bin ${CMAKE_INSTALL_PREFIX}/bin
  )
ENDIF( NOT SWIG_EXECUTABLE)

IF ( NOT SWIG_EXECUTABLE )
  MESSAGE( FATAL "SWIG not found." )
ELSE ( NOT SWIG_EXECUTABLE )
  MESSAGE( STATUS "SWIG found at ${SWIG_EXECUTABLE}" )
ENDIF ( NOT SWIG_EXECUTABLE )


####################################################################
# Directories                                                      #
####################################################################

# don't build standalone provider, its included in the swig code
#ADD_SUBDIRECTORY(src)

ADD_SUBDIRECTORY(swig)
ADD_SUBDIRECTORY(mof)


####################################################################
# RPM SPEC                                                         #
####################################################################

MACRO(SPECFILE)
  IF (NOT EXISTS /.buildenv)
  MESSAGE(STATUS "Writing spec file...")
  CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/package/${PACKAGE}.spec.in ${CMAKE_BINARY_DIR}/package/${PACKAGE}.spec @ONLY)
  #MESSAGE(STATUS "I hate you rpm-lint...!!!")
  #CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/package/${PACKAGE}-rpmlint.in ${CMAKE_BINARY_DIR}/package/${PACKAGE}-rpmlintrc @ONLY)
  ENDIF (NOT EXISTS /.buildenv)
ENDMACRO(SPECFILE)

SPECFILE()

ADD_CUSTOM_TARGET( svncheck
  COMMAND cd $(CMAKE_SOURCE_DIR) && ! LC_ALL=C svn status --show-updates --quiet | grep -v '^Status against revision'
)

SET( AUTOBUILD_COMMAND
  COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/package/*.tar.bz2
  COMMAND ${CMAKE_MAKE_PROGRAM} package_source
  COMMAND ${CMAKE_COMMAND} -E copy ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.bz2 ${CMAKE_BINARY_DIR}/package
  COMMAND ${CMAKE_COMMAND} -E remove ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.bz2
  COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_SOURCE_DIR}/package/${PACKAGE}.changes" "${CMAKE_BINARY_DIR}/package/${PACKAGE}.changes"
)

ADD_CUSTOM_TARGET( srcpackage_local
  ${AUTOBUILD_COMMAND}
)

ADD_CUSTOM_TARGET( srcpackage
  COMMAND ${CMAKE_MAKE_PROGRAM} svncheck
  ${AUTOBUILD_COMMAND}
)
