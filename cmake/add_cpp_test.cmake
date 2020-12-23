# Helper so we don't have to repeat ourselves so much
# Usage: add_cpp_test(<testname>
#                     [COMPILE_ONLY]
#                     [DEBUG_ONLY]
#                     [WILL_FAIL]
#                     [SOURCES a.cpp b.cpp ...]
#                     [LABELS acceptance per_implementation ...])
# SOURCES defaults to <testname>.cpp if not specified.
function(add_cpp_test TEST_NAME)
  # Parse arguments
  cmake_parse_arguments(PARSE_ARGV 1 ARGS "COMPILE_ONLY;LIBRARY;WILL_FAIL;DEBUG_ONLY" "" "SOURCES;LABELS")

  # Is generator multi-config?
  get_cmake_property(is_multi_config GENERATOR_IS_MULTI_CONFIG)

  # Return if debug only test
  if(NOT is_multi_config AND ARGS_DEBUG_ONLY AND NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    return()
  endif()

  # Set configurations
  if(is_multi_config AND ARGS_DEBUG_ONLY)
    set(CONFIG_ARGS CONFIGURATIONS Debug)
  endif()

  if(NOT ARGS_SOURCES)
    list(APPEND ARGS_SOURCES ${TEST_NAME}.cpp)
  endif()

  # Wrap sources in a generator expression and provide a dummy source
  if(is_multi_config AND ARGS_DEBUG_ONLY)
    list(TRANSFORM ARGS_SOURCES PREPEND "$<$<CONFIG:Debug>:")
    list(TRANSFORM ARGS_SOURCES APPEND ">")
    list(PREPEND ARGS_SOURCES "$<$<NOT:$<CONFIG:Debug>>:${simdjson_SOURCE_DIR}/cmake/empty.cpp>")
  endif()

  if(ARGS_COMPILE_ONLY)
    list(APPEND ARGS_LABELS compile)
  endif()

  # Add the compile target
  if(ARGS_LIBRARY)
    add_library(${TEST_NAME} STATIC ${ARGS_SOURCES})
  else()
    add_executable(${TEST_NAME} ${ARGS_SOURCES})
  endif()

  # Add test
  if(ARGS_COMPILE_ONLY OR ARGS_LIBRARY)
    add_test(
      NAME ${TEST_NAME}
      COMMAND ${CMAKE_COMMAND} --build . --target ${TEST_NAME} --config $<CONFIGURATION>
      WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
      ${CONFIG_ARGS}
    )
    set_target_properties(${TEST_NAME} PROPERTIES EXCLUDE_FROM_ALL TRUE EXCLUDE_FROM_DEFAULT_BUILD TRUE)
  else()
    add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME} ${CONFIG_ARGS})
  endif()

  if(ARGS_LABELS)
    set_property(TEST ${TEST_NAME} APPEND PROPERTY LABELS ${ARGS_LABELS})
  endif()

  if(ARGS_WILL_FAIL)
    set_property(TEST ${TEST_NAME} PROPERTY WILL_FAIL TRUE)
  endif()
endfunction()

function(add_compile_only_test TEST_NAME)
  add_test(
    NAME ${TEST_NAME}
    COMMAND ${CMAKE_COMMAND} --build . --target ${TEST_NAME} --config $<CONFIGURATION>
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  )
  set_target_properties(${TEST_NAME} PROPERTIES EXCLUDE_FROM_ALL TRUE EXCLUDE_FROM_DEFAULT_BUILD TRUE)
endfunction()
