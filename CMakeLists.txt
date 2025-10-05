cmake_minimum_required(VERSION 3.31)
project(nano LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(nano src/main.cpp)
