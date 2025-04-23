cmake_minimum_required(VERSION 3.22)

set(CMAKE_CXX_COMPILER /usr/bin/g++)
set(CMAKE_CXX_STANDARD 20)

project(pather VERSION 1.0.0 LANGUAGES C CXX)
include(FetchContent)

FetchContent_Declare(msgpack
  GIT_REPOSITORY https://github.com/msgpack/msgpack-c.git
  GIT_TAG cpp-7.0.0
)
FetchContent_MakeAvailable(msgpack)

FetchContent_Declare(mongoose
    GIT_REPOSITORY https://github.com/cesanta/mongoose.git
    GIT_TAG 7.17
)
FetchContent_MakeAvailable(mongoose)
add_library(MongooseStatic STATIC
        ${mongoose_SOURCE_DIR}/mongoose.c)
target_include_directories(MongooseStatic PUBLIC
        ${mongoose_SOURCE_DIR})

FetchContent_Declare(json URL https://github.com/nlohmann/json/releases/download/v3.12.0/json.tar.xz)
FetchContent_MakeAvailable(json)

find_package(nanoflann REQUIRED)

file(GLOB_RECURSE SRC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
add_executable(${PROJECT_NAME} ${SRC_FILES})
target_include_directories(${PROJECT_NAME} PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include)

target_link_libraries(${PROJECT_NAME} PRIVATE MongooseStatic)
target_link_libraries(${PROJECT_NAME} PRIVATE msgpack-cxx)
target_link_libraries(${PROJECT_NAME} PRIVATE nlohmann_json::nlohmann_json)
target_link_libraries(${PROJECT_NAME} PRIVATE nanoflann::nanoflann)
