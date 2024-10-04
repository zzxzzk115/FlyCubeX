-- target defination, name: example-triangle
target("example-triangle")
    -- set target kind: executable
    set_kind("binary")

    add_includedirs("include", { public = true })

    -- add header & source files
    add_headerfiles("include/**.hpp")
    add_files("src/**.cpp")

    -- add dependencies
    add_deps("FlyCubeX-static")