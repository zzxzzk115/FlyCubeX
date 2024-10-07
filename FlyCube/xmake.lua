if is_plat("windows") then 
    add_requires("directx-headers", "directxshadercompiler")
end

if has_config("vulkan_support") then 
    add_requires("vulkan-hpp", "vulkansdk")
end

add_requires("gli", "glm", "shaderc", "spirv-cross", "nowide_standalone")

target("FlyCubeX-lib")
    set_kind("$(kind)")

    if is_kind("shared") then
        add_rules("utils.symbols.export_all")
    end

    add_includedirs(".", "$(projectdir)/external/dxc/include", { public = true })
    add_headerfiles("$(projectdir)/(FlyCube/**.h)")

    add_files(
        "Framebuffer/FramebufferBase.cpp",
        "ShaderCompiler/Compiler.cpp",
        "ShaderCompiler/DXCLoader.cpp",
        "ShaderCompiler/MSLConverter.cpp",
        "Instance/Instance.cpp",
        "Program/ProgramBase.cpp",
        "Resource/ResourceBase.cpp",
        "Resource/ResourceStateTracker.cpp",
        "Shader/ShaderBase.cpp",
        "ShaderReflection/ShaderReflection.cpp",
        "Utilities/Common.cpp",
        "Utilities/DXGIFormatHelper.cpp",
        "Utilities/FormatHelper.cpp",
        "Utilities/SystemUtils.cpp"
    )

    -- MacOS ARC support
    if is_plat("macosx") then
        add_cxxflags("-fobjc-arc")
    end

    -- DirectX support
    if is_plat("windows") then
        add_files("**/DX*.cpp", "ShaderReflection/SPIRVReflection.cpp")
        add_packages("directx-headers", "directxshadercompiler", { public = true })
    end

    -- Metal support
    if is_plat("macosx") then
        add_files("**/MT*.mm")
        add_frameworks("Foundation", "QuartzCore", "Metal")
    end

    -- Vulkan support
    if has_config("vulkan_support") then
        add_files("**/VK*.cpp", "ShaderReflection/SPIRVReflection.cpp")
        add_packages("vulkan-hpp", "vulkansdk", { public = true })
    end

    add_packages("gli", "glm", "shaderc", "spirv-cross", "nowide_standalone", { public = true })
