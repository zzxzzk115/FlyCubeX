-- target defination, name: AppSettings
target("AppSettings")
    -- set target kind: static
    set_kind("static")

    add_includedirs("..", "$(projectdir)/FlyCube", { public = true })

    -- add header & source files
    add_headerfiles("*.h")
    add_files("*.cpp")