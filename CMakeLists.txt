cmake_minimum_required(VERSION 3.20)
project(Nano LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(Nano src/main.cpp)
add_subdirectory(tests)