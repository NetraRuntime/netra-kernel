cmake_minimum_required(VERSION 3.21)
project(netra_reference_engine LANGUAGES C)

find_package(netra-engine CONFIG REQUIRED)
add_executable(netra-reference-engine main.c)
target_link_libraries(netra-reference-engine PRIVATE netra::netra_engine)
