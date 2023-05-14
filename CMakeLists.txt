cmake_minimum_required(VERSION 3.24)
set(project_name "assemblerProject2")

set(CMAKE_CXX_STANDARD 17)

set(CAN_USE_ASSEMBLER TRUE)
set(CMAKE_ASM_NASM_OBJECT_FORMAT macho64)
set(CMAKE_NASM_LINK_EXECUTABLE "ld <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

if (UNIX AND NOT APPLE)
    set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
endif (UNIX AND NOT APPLE)

project(${project_name} C)

enable_language(ASM_NASM)

set(SOURCE_FILES binaryTest.asm)

add_executable(${project_name} ${SOURCE_FILES})
set_target_properties(${project_name} PROPERTIES LINKER_LANGUAGE NASM)

if (LINUX)
    target_link_libraries(${project_name} System)
endif (LINUX)
