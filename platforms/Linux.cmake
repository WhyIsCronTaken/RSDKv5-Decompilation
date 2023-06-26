# PKG-CONFIG IS USED AS THE MAIN DRIVER
# bc cmake is inconsistent as fuuuckkk

find_package(PkgConfig REQUIRED)

add_executable(RetroEngine ${RETRO_FILES})

set(RETRO_SUBSYSTEM "OGL" CACHE STRING "The subsystem to use")
# WSL doesn't like port audio. this is unfortunately how we fix it
option(USE_SDL_AUDIO "Whether or not to use SDL for audio instead of the default PortAudio." OFF)

pkg_check_modules(OGG ogg)

if(NOT OGG_FOUND)
    set(COMPILE_OGG TRUE)
    message(NOTICE "libogg not found, attempting to build from source")
else()
    message("found libogg")
    target_link_libraries(RetroEngine ${OGG_STATIC_LIBRARIES})
    target_link_options(RetroEngine PRIVATE ${OGG_STATIC_LDLIBS_OTHER})
    target_compile_options(RetroEngine PRIVATE ${OGG_STATIC_CFLAGS})
endif()

pkg_check_modules(THEORA theora theoradec)

if(NOT THEORA_FOUND)
    message("could not find libtheora, attempting to build manually")
    set(COMPILE_THEORA TRUE)
else()
    message("found libtheora")
    target_link_libraries(RetroEngine ${THEORA_STATIC_LIBRARIES})
    target_link_options(RetroEngine PRIVATE ${THEORA_STATIC_LDLIBS_OTHER})
    target_compile_options(RetroEngine PRIVATE ${THEORA_STATIC_CFLAGS})
endif()

if(RETRO_SUBSYSTEM STREQUAL "OGL")
    pkg_check_modules(GLFW glfw3)

    if(NOT GLFW_FOUND)
        message("could not find glfw, attempting to build from source")
        add_subdirectory(dependencies/ogl/glfw)
    else()
        message("found GLFW")
        target_link_libraries(RetroEngine ${GLFW_STATIC_LIBRARIES})
        target_link_options(RetroEngine PRIVATE ${GLFW_STATIC_LDLIBS_OTHER})
        target_compile_options(RetroEngine PRIVATE ${GLFW_STATIC_CFLAGS})
    endif()

    pkg_check_modules(GLEW glew)

    if(NOT GLEW_FOUND)
        message(NOTICE "could not find glew, attempting to build from source")

    else()
        message("found GLEW")
        target_link_libraries(RetroEngine ${GLEW_STATIC_LIBRARIES})
        target_link_options(RetroEngine PRIVATE ${GLEW_STATIC_LDLIBS_OTHER})
        target_compile_options(RetroEngine PRIVATE ${GLEW_STATIC_CFLAGS})
    endif()
elseif(RETRO_SUBSYSTEM STREQUAL "VK")
    find_package(glfw3 CONFIG)

    if(NOT glfw3_FOUND)
        message("could not find glfw, attempting to build from source")
        add_subdirectory(dependencies/ogl/glfw)
    else()
        message("found GLFW")
    endif()

    find_package(Vulkan REQUIRED)

    target_compile_definitions(RetroEngine VULKAN_USE_GLFW=1)
    target_link_libraries(RetroEngine
        glfw
        Vulkan::Vulkan
    )
elseif(RETRO_SUBSYSTEM STREQUAL "SDL2")
    pkg_check_modules(SDL2 sdl2 REQUIRED)
    target_link_libraries(RetroEngine ${SDL2_STATIC_LIBRARIES})
    target_link_options(RetroEngine PRIVATE ${SDL2_STATIC_LDLIBS_OTHER})
    target_compile_options(RetroEngine PRIVATE ${SDL2_STATIC_CFLAGS})
endif()

if(NOT RETRO_SUBSYSTEM STREQUAL SDL2)
    if(NOT USE_SDL_AUDIO)
        pkg_check_modules(PORTAUDIO portaudio-2.0)

        if(NOT PORTAUDIO_FOUND)
            message("could not find portaudio, attempting to build from source")
            add_subdirectory(dependencies/all/portaudio)
        else()
            message("found portaudio")
            target_link_libraries(RetroEngine ${PORTAUDIO_STATIC_LIBRARIES})
            target_link_options(RetroEngine PRIVATE ${PORTAUDIO_STATIC_LDLIBS_OTHER})
            target_compile_options(RetroEngine PRIVATE ${PORTAUDIO_STATIC_CFLAGS})
        endif()
    else()
        pkg_check_modules(SDL2 sdl2 REQUIRED)
        target_link_libraries(RetroEngine ${SDL2_STATIC_LIBRARIES})
        target_link_options(RetroEngine PRIVATE ${SDL2_STATIC_LDLIBS_OTHER})
        target_compile_options(RetroEngine PRIVATE ${SDL2_STATIC_CFLAGS})
        target_compile_definitions(RetroEngine PRIVATE RETRO_AUDIODEVICE_SDL2=1)
    endif()
endif()

if(RETRO_MOD_LOADER)
    set_target_properties(RetroEngine PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED ON
    )
endif()