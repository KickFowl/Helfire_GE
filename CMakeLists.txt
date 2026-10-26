cmake_minimum_required(VERSION 3.24)
project(MyVulkanApp LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

# ------------------------------------------------------------
# Libraries
# ------------------------------------------------------------
FetchContent_Declare(vulkan_headers
  GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
  GIT_TAG        v1.3.296
  GIT_SHALLOW    TRUE)

FetchContent_Declare(volk
  GIT_REPOSITORY https://github.com/zeux/volk.git
  GIT_TAG        1.3.295
  GIT_SHALLOW    TRUE)

FetchContent_Declare(glm
  GIT_REPOSITORY https://github.com/g-truc/glm.git
  GIT_TAG        1.0.1
  GIT_SHALLOW    TRUE)

# Exposes vkCreateWin32SurfaceKHR etc. through volk
set(VOLK_STATIC_DEFINES VK_USE_PLATFORM_WIN32_KHR)

FetchContent_MakeAvailable(vulkan_headers volk glm)

# ------------------------------------------------------------
# Shader compiler (glslang, built from source, pinned)
# ------------------------------------------------------------
FetchContent_Declare(glslang
  GIT_REPOSITORY https://github.com/KhronosGroup/glslang.git
  GIT_TAG        16.6.0
  GIT_SHALLOW    TRUE)

set(ENABLE_OPT ON CACHE BOOL "" FORCE)
set(ENABLE_OPT OFF CACHE BOOL "" FORCE)              # skip SPIRV-Tools dependency
set(ENABLE_HLSL OFF CACHE BOOL "" FORCE)             # GLSL only
set(ENABLE_GLSLANG_BINARIES ON CACHE BOOL "" FORCE)  # need the command-line compiler
set(BUILD_EXTERNAL OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(ENABLE_CTEST OFF CACHE BOOL "" FORCE)
set(GLSLANG_TESTS OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(glslang)

# ------------------------------------------------------------
# Application
# ------------------------------------------------------------
add_executable(app WIN32 src/main.cpp)   # remove WIN32 if you want a console window
target_link_libraries(app PRIVATE volk glm::glm Vulkan::Headers)

# ------------------------------------------------------------
# Shaders: compile shaders/*.vert|frag|comp -> <build>/shaders/<name>.spv
# ------------------------------------------------------------
file(GLOB SHADER_SOURCES CONFIGURE_DEPENDS
  "${CMAKE_SOURCE_DIR}/shaders/*.vert"
  "${CMAKE_SOURCE_DIR}/shaders/*.frag"
  "${CMAKE_SOURCE_DIR}/shaders/*.comp")

set(SPV_OUTPUTS "")
foreach(SRC ${SHADER_SOURCES})
  get_filename_component(NAME ${SRC} NAME)
  set(OUT "${CMAKE_BINARY_DIR}/shaders/${NAME}.spv")
  add_custom_command(
    OUTPUT  ${OUT}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/shaders"
    COMMAND glslang-standalone -V ${SRC} -o ${OUT}
    DEPENDS ${SRC} glslang-standalone
    COMMENT "Compiling ${NAME}"
    VERBATIM)
  list(APPEND SPV_OUTPUTS ${OUT})
endforeach()

add_custom_target(shaders DEPENDS ${SPV_OUTPUTS})
add_dependencies(app shaders)

# Copy compiled shaders next to the exe so the app can load "shaders/<name>.spv"
add_custom_command(TARGET app POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_BINARY_DIR}/shaders" "$<TARGET_FILE_DIR:app>/shaders")