cmake_minimum_required(VERSION 3.20)
project(NanoTests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/out)

# Baixa o GoogleTest se não estiver disponível no sistema
include(FetchContent)
FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/heads/main.zip
)
# Força build sem testes do próprio gtest
set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

enable_testing()

# Cria o executável de testes
add_executable(NanoTests
        tests_main.cpp
)
target_include_directories(NanoTests
        PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(NanoTests
        PRIVATE
        GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(NanoTests)
