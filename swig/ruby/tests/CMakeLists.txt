#
# CMakeLists.txt for cmpi-bindings/swig/ruby/test
#
ENABLE_TESTING()
ADD_TEST(bindings_ruby_loading ruby ${CMAKE_CURRENT_SOURCE_DIR}/loading.rb )
