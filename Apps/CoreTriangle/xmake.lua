-- target defination, name: CoreTriangle
target("CoreTriangle")
    -- set target kind: executable
    set_kind("binary")

    -- set values
    set_values("asset_files", "assets/shaders/CoreTriangle/**")

    -- add rules
    add_rules("copy_assets", "copy_dxc_libs")

    -- add source file
    add_files("main.cpp")

    -- add dependencies
    add_deps("AppBox", "FlyCubeX-lib")