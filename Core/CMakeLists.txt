cmake_minimum_required(VERSION 3.4.1...3.27)
project(dexkit)

find_program(CCACHE ccache)

if (CCACHE)
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE})
    set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE})
endif ()

set(CMAKE_CXX_STANDARD 20)
option(DEXKIT_ENABLE_INTERNAL_METRICS "Compile internal metrics into core" OFF)

file(GLOB_RECURSE SLICER_SRC_FILES CONFIGURE_DEPENDS third_party/slicer/*.cc)
file(GLOB_RECURSE DEXKIT_SRC_FILES CONFIGURE_DEPENDS dexkit/*.cpp)

set(SLICER_SOURCES
        ${SLICER_SRC_FILES}
)

set(COMPILE_FLAGS "-Wno-empty-body -Wno-unused-private-field \
    -Wno-unused-value -Wno-unused-variable -Wno-unused-function")
set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} ${COMPILE_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMPILE_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")

set(DEXKIT_ZLIB_LIBRARY z)
if (UNIX AND NOT APPLE AND USE_MUSL_LIBC)
    set(DEXKIT_ORIGINAL_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
    set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
    find_library(DEXKIT_ZLIB_STATIC_LIBRARY NAMES z)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${DEXKIT_ORIGINAL_FIND_LIBRARY_SUFFIXES})
    if (NOT DEXKIT_ZLIB_STATIC_LIBRARY)
        message(FATAL_ERROR "Can not find static zlib for musl all-in-one build. Please install zlib-static.")
    endif ()
    set(DEXKIT_ZLIB_LIBRARY "${DEXKIT_ZLIB_STATIC_LIBRARY}")
endif ()

add_library(${PROJECT_NAME}_static
        STATIC
        ${SLICER_SOURCES}
        ${DEXKIT_SRC_FILES}
)
target_include_directories(${PROJECT_NAME}_static
        PUBLIC
        dexkit/include
        third_party/slicer/export
        third_party/thread_helper
        third_party/aho_corasick_trie
        third_party/parallel_hashmap
        third_party/flatbuffers/include
)

set_target_properties(${PROJECT_NAME}_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
if (DEXKIT_ENABLE_INTERNAL_METRICS)
    target_compile_definitions(${PROJECT_NAME}_static PUBLIC DEXKIT_ENABLE_INTERNAL_METRICS=1)
else ()
    target_compile_definitions(${PROJECT_NAME}_static PUBLIC DEXKIT_ENABLE_INTERNAL_METRICS=0)
endif ()
target_link_libraries(${PROJECT_NAME}_static
        PUBLIC
        ${DEXKIT_ZLIB_LIBRARY}
)

option(EXECUTABLE_TEST "execute test cpp" OFF)
if (EXECUTABLE_TEST)
    link_libraries(z ${PROJECT_NAME}_static)
    add_executable(${PROJECT_NAME}
            main.cpp
            )
endif ()
