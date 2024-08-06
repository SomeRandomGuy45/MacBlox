cmake_minimum_required(VERSION 3.15)

# Define the project
project(MacbloxApp VERSION 1.0 LANGUAGES CXX)


execute_process(
        COMMAND whoami
        OUTPUT_VARIABLE CURRENT_USER
        OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Define the build path
set(BUILDPATH ${CMAKE_BINARY_DIR}/build)

# Find wxWidgets package
find_package(wxWidgets REQUIRED COMPONENTS core base)

# Set the wxWidgets flags
include(${wxWidgets_USE_FILE})
include_directories(/usr/local/include)

# Add the sources
set(RUNNER_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/runner/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/runner/helper.mm
)

set(MAIN_APP_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/main_app/main.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/main_app/Downloader.mm
)

set(linker_stuff
    ${CMAKE_CURRENT_SOURCE_DIR}/test/main.cpp
)


# Add the executable for the runner
add_executable(runner ${RUNNER_SOURCES})
target_compile_options(runner PRIVATE -x objective-c++)
target_link_libraries(runner ${wxWidgets_LIBRARIES} discord-rpc curl curlpp z minizip "-framework CoreFoundation" "-framework DiskArbitration" "-framework Foundation" "-framework Cocoa" "-framework UserNotifications" ssl crypto)

# Add the executable for the main app
add_executable(main_app ${MAIN_APP_SOURCES})
target_compile_options(main_app PRIVATE -x objective-c++)
target_link_libraries(main_app ${wxWidgets_LIBRARIES} discord-rpc curl curlpp z minizip "-framework CoreFoundation" "-framework DiskArbitration" "-framework Foundation" "-framework Cocoa" "-framework UserNotifications" ssl crypto)

#for testing
add_executable(test_source ${linker_stuff})
target_compile_options(main_app PRIVATE -x objective-c++)
target_link_libraries(main_app ${wxWidgets_LIBRARIES} discord-rpc curl curlpp z minizip "-framework CoreFoundation" "-framework DiskArbitration" "-framework Foundation" "-framework Cocoa" "-framework UserNotifications" ssl crypto)

# Custom command to create directories
add_custom_command(TARGET runner POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${BUILDPATH}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${BUILDPATH}/Macblox
)

# Custom command to appify and codesign the main app
add_custom_command(TARGET test_source POST_BUILD
        COMMAND /Users/${CURRENT_USER}/Desktop/Projects/Macblox/appify -s ${CMAKE_CURRENT_SOURCE_DIR}/build/runner -n play -i test
        COMMAND codesign --sign - --entitlements /Users/${CURRENT_USER}/Desktop/Projects/Macblox/Macblox.plist --deep ${CMAKE_CURRENT_SOURCE_DIR}/build/play.app --force
        COMMAND ${CMAKE_COMMAND} -E rename ${CMAKE_CURRENT_SOURCE_DIR}/build/play.app ${BUILDPATH}/play.app
        COMMAND ${CMAKE_COMMAND} -E rename ${BUILDPATH}/play.app ${BUILDPATH}/Macblox/"Play Roblox.app"
        COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_CURRENT_SOURCE_DIR}/build/runner
        COMMAND /Users/${CURRENT_USER}/Desktop/Projects/Macblox/appify -s ${CMAKE_CURRENT_SOURCE_DIR}/build/main_app -n Macblox -i test
        COMMAND codesign --sign - --entitlements /Users/${CURRENT_USER}/Desktop/Projects/Macblox/Macblox.plist --deep ${CMAKE_CURRENT_SOURCE_DIR}/build/Macblox.app --force
        COMMAND ${CMAKE_COMMAND} -E rename ${CMAKE_CURRENT_SOURCE_DIR}/build/Macblox.app ${BUILDPATH}/Macblox/Macblox.app
        COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_CURRENT_SOURCE_DIR}/build/main
)
