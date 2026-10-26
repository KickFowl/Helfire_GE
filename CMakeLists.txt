cmake_minimum_required(VERSION 3.24)
project(MyVulkanApp LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

# ---- Libraries (source, built with your project) ----
FetchContent_Declare(vulkan_headers
  GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
  GIT_TAG        v1.3.296 GIT_SHALLOW TRUE)
FetchContent_Declare(volk
  GIT_REPOSITORY https://github.com/zeux/volk.git
  GIT_TAG        1.3.295 GIT_SHALLOW TRUE)
FetchContent_Declare(glfw
  GIT_REPOSITORY https://github.com/glfw/glfw.git
  GIT_TAG        3.4 GIT_SHALLOW TRUE)
FetchContent_Declare(glm
  GIT_REPOSITORY https://github.com/g-truc/glm.git
  GIT_TAG        1.0.1 GIT_SHALLOW TRUE)

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(vulkan_headers volk glfw glm)

# ---- Shader compiler (prebuilt Khronos binary, no build step) ----
FetchContent_Declare(glslang_bin
  URL https://github.com/KhronosGroup/glslang/releases/download/main-tot/glslang-main-windows-Release.zip)
FetchContent_MakeAvailable(glslang_bin)
set(GLSLANG_VALIDATOR "${glslang_bin_SOURCE_DIR}/bin/glslangValidator.exe")

# ---- App ----
add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE volk glfw glm::glm Vulkan::Headers)

# ---- Shaders: compile every .vert/.frag/.comp into <build>/shaders/*.spv ----
file(GLOB SHADER_SOURCES CONFIGURE_DEPENDS
  shaders/*.vert shaders/*.frag shaders/*.comp)

set(SPV_OUTPUTS "")
foreach(SRC ${SHADER_SOURCES})
  get_filename_component(NAME ${SRC} NAME)
  set(OUT "${CMAKE_BINARY_DIR}/shaders/${NAME}.spv")
  add_custom_command(
    OUTPUT ${OUT}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/shaders"
    COMMAND ${GLSLANG_VALIDATOR} -V ${SRC} -o ${OUT}
    DEPENDS ${SRC}
    COMMENT "Compiling ${NAME}")
  list(APPEND SPV_OUTPUTS ${OUT})
endforeach()

add_custom_target(shaders DEPENDS ${SPV_OUTPUTS})
add_dependencies(app shaders)

# Copy compiled shaders next to the exe so the app can load "shaders/x.spv"
add_custom_command(TARGET app POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_BINARY_DIR}/shaders" "$<TARGET_FILE_DIR:app>/shaders")
