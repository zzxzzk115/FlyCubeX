add_requires("glfw")

-- target defination, name: AppLoop
target("AppLoop")
    -- set target kind: static
    set_kind("static")

    add_includedirs("..", "$(projectdir)/FlyCube", { public = true })

    -- add header & source files
    add_headerfiles("*.h")

    -- TODO: Consider iOS and tvOS
    add_headerfiles("GLFW/**.h")
    add_files("GLFW/**.cpp")

    add_packages("glfw", { public = true })