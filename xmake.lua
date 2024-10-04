-- set project name
set_project("FlyCubeX")

-- set project version
set_version("1.0.0")

-- set language version: C++ 20
set_languages("cxx20")

-- if build on windows
if is_plat("windows") then
    if is_mode("debug") then
        set_runtimes("MDd")
        add_links("ucrtd")
    else
        set_runtimes("MD")
    end
end

-- enable exceptions
set_exceptions("cxx")

add_rules("mode.debug", "mode.release")
add_rules("plugin.vsxmake.autoupdate")
add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})

-- add my own xmake-repo here
add_repositories("my-xmake-repo https://github.com/zzxzzk115/xmake-repo.git dev")

includes("FlyCube")