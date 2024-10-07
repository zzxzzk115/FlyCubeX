-- set project name
set_project("FlyCubeX")

-- set project version
set_version("1.0.0")

-- set language version: C++ 20
set_languages("cxx20")

-- global options
option("vulkan_support")
    set_default(true)
option_end()

option("build_apps")
    set_default(true)
option_end()

-- if build on windows
if is_plat("windows") then
    if is_mode("debug") then
        set_runtimes("MDd")
        add_syslinks("ucrtd")
    else
        set_runtimes("MD")
    end
    -- DX support
    add_syslinks("d3d12", "dxgi", "dxguid")
    add_defines("DIRECTX_SUPPORT", "NOMINMAX")
end
-- Linux links
if is_plat("linux") then
    add_syslinks("dl", "X11-xcb")
end
-- Metal support
if is_plat("macosx") then
    add_defines("METAL_SUPPORT")
end
-- Vulkan support
if has_config("vulkan_support") then
    add_defines("VULKAN_SUPPORT")
end

-- enable exceptions
set_exceptions("cxx")

-- global rules
rule("copy_assets")
    after_build(function (target)
        local asset_files = target:values("asset_files")
        if asset_files then
            for _, file in ipairs(asset_files) do
                local relpath = path.relative(file, os.projectdir())
                local target_dir = path.join(target:targetdir(), path.directory(relpath))
                os.mkdir(target_dir)
                os.cp(file, target_dir)
                print("Copying asset: " .. file .. " -> " .. target_dir)
            end
        end
    end)
rule_end()

rule("copy_dxc_libs")
    after_build(function (target)
        os.cp("tools/$(plat)/$(arch)/dxc/dx*.dll", target:targetdir())
    end)
rule_end()

add_rules("mode.debug", "mode.release")
add_rules("plugin.vsxmake.autoupdate")
add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})

-- add my own xmake-repo here
add_repositories("my-xmake-repo https://github.com/zzxzzk115/xmake-repo.git dev")

includes("FlyCube")

if has_config("build_apps") then
    includes("Modules")
    includes("Apps")
end