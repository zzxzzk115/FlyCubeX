add_requires("directx-headers", "directxshadercompiler", "gli", "glm", "spirv-cross", "nowide_standalone")

target("FlyCubeX-static")
    set_kind("static")

    add_includedirs(".", "$(projectdir)/external/dxc/include")
    
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
        "Program/ProgramBase.cpp",
        "Resource/ResourceBase.cpp",
        "Shader/ShaderBase.cpp",
        "ShaderReflection/ShaderReflection.cpp",
        "Utilities/Common.cpp"
    )

    -- MacOS ARC support
    if is_plat("macosx") then
        add_cxxflags("-fobjc-arc")
    end

    -- DirectX support
    if has_config("directx_support") then
        add_headerfiles(
            "Adapter/DXAdapter.h",
            "BindingSet/DXBindingSet.h",
            "BindingSetLayout/DXBindingSetLayout.h",
            "CPUDescriptorPool/DXCPUDescriptorHandle.h",
            "CPUDescriptorPool/DXCPUDescriptorPool.h",
            "CommandList/DXCommandList.h",
            "CommandQueue/DXCommandQueue.h",
            "Device/DXDevice.h",
            "Fence/DXFence.h",
            "Framebuffer/DXFramebuffer.h",
            "GPUDescriptorPool/DXGPUDescriptorPool.h",
            "Memory/DXMemory.h",
            "Pipeline/DXPipeline.h",
            "RenderPass/DXRenderPass.h",
            "Resource/DXResource.h",
            "ShaderReflection/DXILReflection.h",
            "Swapchain/DXSwapchain.h"
        )
        add_files(
            "Adapter/DXAdapter.cpp",
            "BindingSet/DXBindingSet.cpp",
            "BindingSetLayout/DXBindingSetLayout.cpp",
            "CPUDescriptorPool/DXCPUDescriptorHandle.cpp",
            "CPUDescriptorPool/DXCPUDescriptorPool.cpp",
            "CommandList/DXCommandList.cpp",
            "CommandQueue/DXCommandQueue.cpp",
            "Device/DXDevice.cpp",
            "Fence/DXFence.cpp",
            "GPUDescriptorPool/DXGPUDescriptorPool.cpp",
            "Memory/DXMemory.cpp",
            "Pipeline/DXComputePipeline.cpp",
            "Pipeline/DXGraphicsPipeline.cpp",
            "Pipeline/DXRayTracingPipeline.cpp",
            "RenderPass/DXRenderPass.cpp",
            "Resource/DXResource.cpp",
            "ShaderReflection/DXILReflection.cpp",
            "Swapchain/DXSwapchain.cpp"
        )
        add_links("d3d12", "dxgi", "dxguid")
    end

    -- Metal support
    if has_config("metal_support") then
        add_headerfiles(
            "Adapter/MTAdapter.h",
            "BindingSet/MTBindingSet.h",
            "BindingSetLayout/MTBindingSetLayout.h",
            "CommandList/MTCommandList.h",
            "CommandQueue/MTCommandQueue.h",
            "Device/MTDevice.h",
            "Fence/MTFence.h",
            "Framebuffer/MTFramebuffer.h",
            "GPUDescriptorPool/MTGPUBindlessArgumentBuffer.h",
            "Instance/MTInstance.h",
            "Memory/MTMemory.h",
            "Pipeline/MTPipeline.h",
            "RenderPass/MTRenderPass.h",
            "Resource/MTResource.h",
            "Shader/MTShader.h",
            "Swapchain/MTSwapchain.h"
        )
        add_files(
            "Adapter/MTAdapter.mm",
            "BindingSet/MTBindingSet.mm",
            "BindingSetLayout/MTBindingSetLayout.mm",
            "CommandList/MTCommandList.mm",
            "CommandQueue/MTCommandQueue.mm",
            "Device/MTDevice.mm",
            "Fence/MTFence.mm",
            "GPUDescriptorPool/MTGPUBindlessArgumentBuffer.mm",
            "Instance/MTInstance.mm",
            "Memory/MTMemory.mm",
            "Pipeline/MTComputePipeline.mm",
            "Pipeline/MTGraphicsPipeline.mm",
            "RenderPass/MTRenderPass.mm",
            "Resource/MTResource.mm",
            "Shader/MTShader.mm",
            "Swapchain/MTSwapchain.mm"
        )
        add_frameworks("Foundation", "QuartzCore", "Metal")
    end

    -- Vulkan support
    if has_config("vulkan_support") then
        add_headerfiles(
            "Adapter/VKAdapter.h",
            "BindingSet/VKBindingSet.h",
            "BindingSetLayout/VKBindingSetLayout.h",
            "CommandList/VKCommandList.h",
            "CommandQueue/VKCommandQueue.h",
            "Device/VKDevice.h",
            "Fence/VKTimelineSemaphore.h",
            "Framebuffer/VKFramebuffer.h",
            "GPUDescriptorPool/VKGPUDescriptorPool.h",
            "Memory/VKMemory.h",
            "Pipeline/VKPipeline.h",
            "RenderPass/VKRenderPass.h",
            "Resource/VKResource.h",
            "ShaderReflection/SPIRVReflection.h",
            "Swapchain/VKSwapchain.h"
        )
        add_files(
            "Adapter/VKAdapter.cpp",
            "BindingSet/VKBindingSet.cpp",
            "BindingSetLayout/VKBindingSetLayout.cpp",
            "CommandList/VKCommandList.cpp",
            "CommandQueue/VKCommandQueue.cpp",
            "Device/VKDevice.cpp",
            "Fence/VKTimelineSemaphore.cpp",
            "Framebuffer/VKFramebuffer.cpp",
            "GPUDescriptorPool/VKGPUDescriptorPool.cpp",
            "Memory/VKMemory.cpp",
            "Pipeline/VKComputePipeline.cpp",
            "Pipeline/VKGraphicsPipeline.cpp",
            "Pipeline/VKRayTracingPipeline.cpp",
            "RenderPass/VKRenderPass.cpp",
            "Resource/VKResource.cpp",
            "ShaderReflection/SPIRVReflection.cpp",
            "Swapchain/VKSwapchain.cpp"
        )
        add_links("vulkan")
    end

    -- Linux links
    if is_plat("linux") then
        add_links("dl", "X11-xcb")
    end

    add_packages("directx-headers", { public = true})
    add_packages("directxshadercompiler", { public = true})
    add_packages("gli", { public = true})
    add_packages("glm", { public = true})
    add_packages("spirv-cross", { public = true})
    add_packages("nowide_standalone", { public = true})
