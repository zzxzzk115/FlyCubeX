if is_plat("windows") then 
    add_requires("directx-headers", "directxshadercompiler")
end

if has_config("vulkan_support") then 
    add_requires("vulkan-hpp", "vulkansdk")
end

add_requires("gli", "glm", "spirv-cross", "nowide_standalone")

target("FlyCubeX-static")
    set_kind("static")

    add_includedirs(".", "$(projectdir)/external/dxc/include", { public = true })

    add_headerfiles(
        "Adapter/Adapter.h",
        "ApiType/ApiType.h",
        "BindingSet/BindingSet.h",
        "BindingSetLayout/BindingSetLayout.h",
        "CommandList/CommandList.h",
        "CommandQueue/CommandQueue.h",
        "Device/Device.h",
        "Fence/Fence.h",
        "Framebuffer/Framebuffer.h",
        "Framebuffer/FramebufferBase.h",
        "HLSLCompiler/Compiler.h",
        "HLSLCompiler/DXCLoader.h",
        "HLSLCompiler/MSLConverter.h",
        "Instance/Instance.h",
        "Memory/Memory.h",
        "Pipeline/Pipeline.h",
        "Program/Program.h",
        "Program/ProgramBase.h",
        "QueryHeap/QueryHeap.h",
        "RenderPass/RenderPass.h",
        "Resource/Resource.h",
        "Resource/ResourceBase.h",
        "Shader/Shader.h",
        "Shader/ShaderBase.h",
        "ShaderReflection/ShaderReflection.h",
        "Swapchain/Swapchain.h",
        "Utilities/Common.h",
        "Utilities/ScopeGuard.h",
        "View/View.h"
    )

    add_files(
        "Framebuffer/FramebufferBase.cpp",
        "HLSLCompiler/Compiler.cpp",
        "HLSLCompiler/DXCLoader.cpp",
        "HLSLCompiler/MSLConverter.cpp",
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
        add_headerfiles("**/DX*.h")
        add_files("**/DX*.cpp", "ShaderReflection/SPIRVReflection.cpp")
        add_links("d3d12", "dxgi", "dxguid")
        add_packages("directx-headers", "directxshadercompiler", { public = true })
        add_defines("DIRECTX_SUPPORT", "NOMINMAX")
    end

    -- Metal support
    if is_plat("macosx") then
        add_headerfiles("**/MT*.h")
        add_files("**/MT*.mm")
        add_frameworks("Foundation", "QuartzCore", "Metal")
        add_defines("METAL_SUPPORT")
    end

    -- Vulkan support
    if has_config("vulkan_support") then
        add_headerfiles("**/VK*.h")
        add_files("**/VK*.cpp", "ShaderReflection/SPIRVReflection.cpp")
        add_packages("vulkan-hpp", "vulkansdk", { public = true })
        add_defines("VULKAN_SUPPORT")
    end

    -- Linux links
    if is_plat("linux") then
        add_links("dl", "X11-xcb")
    end

    add_packages("gli", "glm", "spirv-cross", "nowide_standalone", { public = true })
