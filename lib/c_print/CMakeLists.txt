cmake_minimum_required(VERSION 3.15)
project(c_print VERSION 1.0.0 LANGUAGES C CXX)

# Opciones de compilación
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Directorios
set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)

# ============================================================================
# ARCHIVOS FUENTE MODULARIZADOS
# ============================================================================

set(SOURCES
    ${SRC_DIR}/c_print.c
    ${SRC_DIR}/ansi_codes.c
    ${SRC_DIR}/color_parser.c
    ${SRC_DIR}/pattern_parser.c
    ${SRC_DIR}/number_formatter.c
    ${SRC_DIR}/text_alignment.c
    ${SRC_DIR}/string_utils.c
    ${SRC_DIR}/c_print_builder.c
    ${SRC_DIR}/c_print_generic.c
)

set(HEADERS
    ${INCLUDE_DIR}/c_print.h
    ${INCLUDE_DIR}/ansi_codes.h
    ${INCLUDE_DIR}/color_parser.h
    ${INCLUDE_DIR}/pattern_parser.h
    ${INCLUDE_DIR}/number_formatter.h
    ${INCLUDE_DIR}/text_alignment.h
    ${INCLUDE_DIR}/string_utils.h
    ${INCLUDE_DIR}/c_print_builder.h
    ${INCLUDE_DIR}/c_print_generic.h
)

# ============================================================================
# BIBLIOTECA COMPARTIDA (.so en Linux, .dll en Windows)
# ============================================================================

add_library(c_print_shared SHARED ${SOURCES} ${HEADERS})
target_include_directories(c_print_shared 
    PUBLIC 
        $<BUILD_INTERFACE:${INCLUDE_DIR}>
        $<INSTALL_INTERFACE:include>
)
set_target_properties(c_print_shared PROPERTIES
    OUTPUT_NAME c_print
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    PUBLIC_HEADER "${HEADERS}"
)

# ============================================================================
# BIBLIOTECA ESTÁTICA (.a en Linux, .lib en Windows)
# ============================================================================

add_library(c_print_static STATIC ${SOURCES} ${HEADERS})
target_include_directories(c_print_static 
    PUBLIC 
        $<BUILD_INTERFACE:${INCLUDE_DIR}>
        $<INSTALL_INTERFACE:include>
)
set_target_properties(c_print_static PROPERTIES
    OUTPUT_NAME c_print
    PUBLIC_HEADER "${HEADERS}"
)

# ============================================================================
# OPCIONES DE COMPILACIÓN
# ============================================================================

if(MSVC)
    target_compile_options(c_print_shared PRIVATE /W4)
    target_compile_options(c_print_static PRIVATE /W4)
else()
    target_compile_options(c_print_shared PRIVATE 
        -Wall -Wextra -pedantic -Wno-unused-parameter
    )
    target_compile_options(c_print_static PRIVATE 
        -Wall -Wextra -pedantic -Wno-unused-parameter
    )
endif()

# ============================================================================
# INSTALACIÓN
# ============================================================================

include(GNUInstallDirs)

install(TARGETS c_print_shared c_print_static
    EXPORT c_print_targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c_print
)

# Instalar archivo de configuración para find_package()
install(EXPORT c_print_targets
    FILE c_print-targets.cmake
    NAMESPACE c_print::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/c_print
)

# Configurar e instalar el archivo pkg-config
configure_file(c_print.pc.in c_print.pc @ONLY)
install(
    FILES ${CMAKE_BINARY_DIR}/c_print.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
)

# ============================================================================
# EJEMPLOS (opcional)
# ============================================================================

option(BUILD_EXAMPLES "Build example programs" ON)

if(BUILD_EXAMPLES)
    # Ejemplo con biblioteca compartida
    add_executable(example_shared test/example.c)
    target_link_libraries(example_shared c_print_shared)
    target_include_directories(example_shared PRIVATE ${INCLUDE_DIR})
    
    # Ejemplo con biblioteca estática
    add_executable(example_static test/example.c)
    target_link_libraries(example_static c_print_static)
    target_include_directories(example_static PRIVATE ${INCLUDE_DIR})
    
    # Ejemplo Builder Pattern
    add_executable(example_builder test/example_builder.c)
    target_link_libraries(example_builder c_print_shared)
    target_include_directories(example_builder PRIVATE ${INCLUDE_DIR})
    
    # Ejemplo C++ (si existe)
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/test/example.cpp)
        add_executable(example_cpp test/example.cpp)
        target_link_libraries(example_cpp c_print_shared)
        target_include_directories(example_cpp PRIVATE ${INCLUDE_DIR})
    endif()
endif()

# ============================================================================
# TESTS (opcional)
# ============================================================================

option(BUILD_TESTS "Build unit tests" OFF)

if(BUILD_TESTS)
    enable_testing()
    
    # Test para string_utils
    add_executable(test_string_utils test/test_string_utils.c)
    target_link_libraries(test_string_utils c_print_static)
    target_include_directories(test_string_utils PRIVATE ${INCLUDE_DIR})
    add_test(NAME StringUtils COMMAND test_string_utils)
    
    # Test para color_parser
    add_executable(test_color_parser test/test_color_parser.c)
    target_link_libraries(test_color_parser c_print_static)
    target_include_directories(test_color_parser PRIVATE ${INCLUDE_DIR})
    add_test(NAME ColorParser COMMAND test_color_parser)
    
    # Test para number_formatter
    add_executable(test_number_formatter test/test_number_formatter.c)
    target_link_libraries(test_number_formatter c_print_static)
    target_include_directories(test_number_formatter PRIVATE ${INCLUDE_DIR})
    add_test(NAME NumberFormatter COMMAND test_number_formatter)
    
    # Test para text_alignment
    add_executable(test_text_alignment test/test_text_alignment.c)
    target_link_libraries(test_text_alignment c_print_static)
    target_include_directories(test_text_alignment PRIVATE ${INCLUDE_DIR})
    add_test(NAME TextAlignment COMMAND test_text_alignment)
    
    # Test para builder
    add_executable(test_builder test/test_builder.c)
    target_link_libraries(test_builder c_print_static)
    target_include_directories(test_builder PRIVATE ${INCLUDE_DIR})
    add_test(NAME Builder COMMAND test_builder)

    # Test para DebugAlignment
    add_executable(debug_alignment test/debug_alignment.c)
    target_link_libraries(debug_alignment c_print_static)
    target_include_directories(debug_alignment PRIVATE ${INCLUDE_DIR})
    add_test(NAME DebugAlignment COMMAND debug_alignment)

    # Test para example_generic
    add_executable(example_generic test/example_generic.c)
    target_link_libraries(example_generic c_print_static)
    target_include_directories(example_generic PRIVATE ${INCLUDE_DIR})
    add_test(NAME ExampleGeneric COMMAND example_generic)

endif()

# ============================================================================
# INFORMACIÓN DE COMPILACIÓN
# ============================================================================

message(STATUS "═══════════════════════════════════════════════════════════")
message(STATUS "  C Print Library Configuration")
message(STATUS "═══════════════════════════════════════════════════════════")
message(STATUS "  Version:         ${PROJECT_VERSION}")
message(STATUS "  Build type:      ${CMAKE_BUILD_TYPE}")
message(STATUS "  C Compiler:      ${CMAKE_C_COMPILER}")
message(STATUS "  Install prefix:  ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Build examples:  ${BUILD_EXAMPLES}")
message(STATUS "  Build tests:     ${BUILD_TESTS}")
message(STATUS "═══════════════════════════════════════════════════════════")
message(STATUS "  Source files:")
foreach(src ${SOURCES})
    get_filename_component(src_name ${src} NAME)
    message(STATUS "    - ${src_name}")
endforeach()
message(STATUS "═══════════════════════════════════════════════════════════")