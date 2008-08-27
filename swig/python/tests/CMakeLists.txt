#
# CMakeLists.txt for cmpi-bindings/swig/python/tests
#

ENABLE_TESTING()

#ADD_TEST(bindings_python_loading     python ${CMAKE_CURRENT_SOURCE_DIR}/loading.py)
ADD_TEST(enum_instance_names bash ${CMAKE_CURRENT_SOURCE_DIR}/enum_instance_names.sh)
ADD_TEST(get_instances bash ${CMAKE_CURRENT_SOURCE_DIR}/get_instances.sh)
