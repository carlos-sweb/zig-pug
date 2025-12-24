cmake_minimum_required(VERSION 3.10)
project(zig-pug-examples C)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Platform detection
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
        set(PLATFORM "linux-x64")
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
        set(PLATFORM "linux-arm64")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(PLATFORM "darwin-arm64")
    else()
        set(PLATFORM "darwin-x64")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(PLATFORM "win32-x64")
endif()

message(STATUS "Building for platform: ${PLATFORM}")

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/../../include)

# Library directories
link_directories(${CMAKE_SOURCE_DIR}/../../libs/${PLATFORM})

# Add examples
add_executable(01-basic 01-basic.c)
target_link_libraries(01-basic zig-pug m)

add_executable(02-variables 02-variables.c)
target_link_libraries(02-variables zig-pug m)

add_executable(03-arrays-objects 03-arrays-objects.c)
target_link_libraries(03-arrays-objects zig-pug m)

add_executable(04-error-handling 04-error-handling.c)
target_link_libraries(04-error-handling zig-pug m)

add_executable(05-file-template 05-file-template.c)
target_link_libraries(05-file-template zig-pug m)

add_executable(06-builder-api 06-builder-api.c)
target_link_libraries(06-builder-api zig-pug m)

# Install targets
install(TARGETS 01-basic 02-variables 03-arrays-objects 04-error-handling 05-file-template 06-builder-api
        RUNTIME DESTINATION bin)

# Print instructions
message(STATUS "")
message(STATUS "Build examples:")
message(STATUS "  mkdir build && cd build")
message(STATUS "  cmake ..")
message(STATUS "  make")
message(STATUS "")
message(STATUS "Run examples:")
message(STATUS "  ./01-basic")
message(STATUS "  ./02-variables")
message(STATUS "  ./03-arrays-objects")
message(STATUS "  ./04-error-handling")
message(STATUS "  ./05-file-template template.pug")
message(STATUS "  ./06-builder-api")
message(STATUS "")
