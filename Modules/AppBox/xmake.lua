add_requires("glfw")

-- target defination, name: AppBox
target("AppBox")
    -- set target kind: static
    set_kind("static")

    add_includedirs("..", "$(projectdir)/FlyCube", { public = true })

    -- add header & source files
    add_headerfiles("AppBox.h", "*Events.h")
    add_files("*.cpp")

    if is_plat("macosx") then 
        add_headerfiles("AutoreleasePool.h")
        add_files("AutoreleasePool.mm")
    end

    add_deps("FlyCubeX-lib", "AppSettings")
    add_packages("glfw", { public = true })