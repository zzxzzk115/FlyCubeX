#include "ShaderCompiler/Compiler.h"

#include "Instance/BaseTypes.h"
#include "ShaderCompiler/DXCLoader.h"
#include "Utilities/Common.h"
#include "Utilities/DXUtility.h"
#include "dxc/dxcapi.h"
#include "shaderc/env.h"
#include "shaderc/shaderc.h"

#include <nowide/convert.hpp>
#include <shaderc/shaderc.hpp>
#include <spirv_cross/spirv_cross.hpp>
#include <spirv_cross/spirv_hlsl.hpp>

#include <cassert>
#include <deque>
#include <exception>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <vector>

namespace {

std::string GetShaderTarget(ShaderType type, const std::string& model)
{
    switch (type) {
    case ShaderType::kPixel:
        return "ps_" + model;
    case ShaderType::kVertex:
        return "vs_" + model;
    case ShaderType::kGeometry:
        return "gs_" + model;
    case ShaderType::kCompute:
        return "cs_" + model;
    case ShaderType::kAmplification:
        return "as_" + model;
    case ShaderType::kMesh:
        return "ms_" + model;
    case ShaderType::kLibrary:
        return "lib_" + model;
    default:
        assert(false);
        return "";
    }
}

shaderc_shader_kind GetShadercKind(ShaderType type)
{
    switch (type) {
    case ShaderType::kPixel:
        return shaderc_glsl_fragment_shader;
    case ShaderType::kVertex:
        return shaderc_glsl_vertex_shader;
    case ShaderType::kGeometry:
        return shaderc_glsl_geometry_shader;
    case ShaderType::kCompute:
        return shaderc_glsl_compute_shader;
    case ShaderType::kMesh:
        return shaderc_glsl_mesh_shader;

        // TODO: Verify
    case ShaderType::kAmplification:
    case ShaderType::kLibrary:
    case ShaderType::kUnknown:
        return shaderc_glsl_default_vertex_shader;
    }
}

ShaderSourceType GetShaderSourceType(const std::string& suffix)
{
    if (suffix == ".hlsl") {
        return ShaderSourceType::kHLSL;
    } else if (suffix == ".glsl") {
        return ShaderSourceType::kGLSL;
    } else {
        return ShaderSourceType::kUnknown;
    }
}

std::vector<uint8_t> Spv2Bytecode(const std::vector<uint32_t>& spv)
{
    size_t byte_size = spv.size() * sizeof(uint32_t);

    std::vector<uint8_t> byte_code(reinterpret_cast<const uint8_t*>(spv.data()),
                                   reinterpret_cast<const uint8_t*>(spv.data()) + byte_size);

    return byte_code;
}

} // namespace

// NOLINTBEGIN
class MyShadercIncluder : public shaderc::CompileOptions::IncluderInterface {
public:
    MyShadercIncluder(const std::vector<std::filesystem::path>& search_paths)
        : search_paths_(search_paths)
    {
    }

    virtual shaderc_include_result* GetInclude(const char* requested_source,
                                               shaderc_include_type type,
                                               const char* requesting_source,
                                               size_t include_depth) override final
    {
        for (const auto& search_path : search_paths_) {
            std::string file_path = (search_path / requested_source).generic_string();
            std::ifstream file_stream(file_path.c_str(), std::ios::binary);
            if (file_stream.is_open()) {
                FileInfo* new_file_info = new FileInfo{ file_path, {} };
                std::vector<char> file_content((std::istreambuf_iterator<char>(file_stream)),
                                               std::istreambuf_iterator<char>());
                new_file_info->contents = file_content;
                return new shaderc_include_result{ new_file_info->path.data(), new_file_info->path.length(),
                                                   new_file_info->contents.data(), new_file_info->contents.size(),
                                                   new_file_info };
            }
        }

        return nullptr;
    }

    virtual void ReleaseInclude(shaderc_include_result* data) override final
    {
        FileInfo* info = static_cast<FileInfo*>(data->user_data);
        delete info;
        delete data;
    }

private:
    struct FileInfo {
        const std::string path;
        std::vector<char> contents;
    };

    std::unordered_set<std::string> included_files_;
    std::vector<std::filesystem::path> search_paths_;
};
// NOLINTEND

class IncludeHandler : public IDxcIncludeHandler {
public:
    IncludeHandler(CComPtr<IDxcLibrary> library, const std::wstring& base_path)
        : m_library(library)
        , m_base_path(base_path)
    {
    }

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** ppvObject) override
    {
        return E_NOTIMPL;
    }
    ULONG STDMETHODCALLTYPE AddRef() override
    {
        return E_NOTIMPL;
    }
    ULONG STDMETHODCALLTYPE Release() override
    {
        return E_NOTIMPL;
    }

    HRESULT STDMETHODCALLTYPE LoadSource(_In_ LPCWSTR pFilename,
                                         _COM_Outptr_result_maybenull_ IDxcBlob** ppIncludeSource) override
    {
        std::wstring path = m_base_path + pFilename;
        CComPtr<IDxcBlobEncoding> source;
        HRESULT hr = m_library->CreateBlobFromFile(path.c_str(), nullptr, &source);
        if (SUCCEEDED(hr) && ppIncludeSource) {
            *ppIncludeSource = source.Detach();
        }
        return hr;
    }

private:
    CComPtr<IDxcLibrary> m_library;
    const std::wstring& m_base_path;
};

std::vector<uint8_t> Compile(const ShaderDesc& shader, ShaderBlobType blob_type)
{
    std::vector<uint8_t> blob;

    decltype(auto) dxc_support = GetDxcSupport(blob_type);

    std::wstring shader_path = nowide::widen(shader.shader_path);
    std::wstring shader_dir = shader_path.substr(0, shader_path.find_last_of(L"\\/") + 1);

    auto shader_fs_path = std::filesystem::path(shader.shader_path);
    auto shader_file_name = shader_fs_path.filename().generic_string();
    auto suffix = shader_fs_path.extension().generic_string();
    auto shader_source_type = GetShaderSourceType(suffix);

    // Handle GLSL source
    bool convert_glsl_to_hlsl = false;
    std::string hlsl_source_text;
    if (shader_source_type == ShaderSourceType::kGLSL) {
        // GLSL Source -> SPV (shaderc)
        shaderc::Compiler compiler;
        shaderc::CompileOptions options;
        options.SetTargetEnvironment(shaderc_target_env_default, shaderc_target_env_default);
        // options.SetOptimizationLevel(shaderc_optimization_level_performance);
        // options.SetAutoMapLocations(false);
        // options.SetAutoBindUniforms(false);
        const auto search_paths = { std::filesystem::path(shader_dir) };
        options.SetIncluder(std::make_unique<MyShadercIncluder>(search_paths));

        // Setup defines
        for (const auto& define : shader.define) {
            options.AddMacroDefinition(define.first, define.second);
        }

        auto glsl_source_text = ReadFileContent(shader_fs_path.generic_string());

        // Preprocess
        auto pre_result =
            compiler.PreprocessGlsl(glsl_source_text, GetShadercKind(shader.type), shader_file_name.c_str(), options);
        if (pre_result.GetCompilationStatus() != shaderc_compilation_status_success) {
            throw std::exception(pre_result.GetErrorMessage().c_str());
        }

        std::string pre_processed_source(pre_result.begin());

        // Compile
        auto compile_result = compiler.CompileGlslToSpv(pre_processed_source, GetShadercKind(shader.type),
                                                        shader_file_name.c_str(), shader.entrypoint.c_str(), options);
        if (compile_result.GetCompilationStatus() != shaderc_compilation_status_success) {
            throw std::exception(compile_result.GetErrorMessage().c_str());
        }
        const auto spv = std::vector<uint32_t>(compile_result.cbegin(), compile_result.cend());

        if (blob_type == ShaderBlobType::kSPIRV) {
            blob = Spv2Bytecode(spv);
        } else if (blob_type == ShaderBlobType::kDXIL) { // SPV -> HLSL Source (SPIRV-Cross)
            spirv_cross::CompilerHLSL::Options hlsl_options{};
            hlsl_options.shader_model = 60;
            hlsl_options.use_entry_point_name = true;
            spirv_cross::CompilerHLSL hlsl_compiler(spv);
            hlsl_compiler.set_hlsl_options(hlsl_options);
            hlsl_source_text = hlsl_compiler.compile();
            convert_glsl_to_hlsl = true;
        }
    }

    // Handle HLSL source
    if (shader_source_type == ShaderSourceType::kHLSL || convert_glsl_to_hlsl) {
        CComPtr<IDxcLibrary> library;
        dxc_support.CreateInstance(CLSID_DxcLibrary, &library);
        CComPtr<IDxcBlobEncoding> source;
        // Create a temporary file for the HLSL source
        if (convert_glsl_to_hlsl) {
            std::string temp_file_path = "temp_hlsl_shader.hlsl";
            {
                std::ofstream temp_file(temp_file_path, std::ios::binary);
                temp_file.write(hlsl_source_text.c_str(), hlsl_source_text.size());
            }
            ASSERT_SUCCEEDED(library->CreateBlobFromFile(nowide::widen(temp_file_path).c_str(), nullptr, &source));
            std::remove(temp_file_path.c_str());
        } else {
            ASSERT_SUCCEEDED(library->CreateBlobFromFile(shader_path.c_str(), nullptr, &source));
        }

        std::wstring target = nowide::widen(GetShaderTarget(shader.type, shader.model));
        std::wstring entrypoint = nowide::widen(shader.entrypoint);
        std::vector<std::pair<std::wstring, std::wstring>> defines_store;
        std::vector<DxcDefine> defines;
        for (const auto& define : shader.define) {
            defines_store.emplace_back(nowide::widen(define.first), nowide::widen(define.second));
            defines.push_back({ defines_store.back().first.c_str(), defines_store.back().second.c_str() });
        }

        std::vector<LPCWSTR> arguments;
        std::deque<std::wstring> dynamic_arguments;
        arguments.push_back(L"/Zi");
        arguments.push_back(L"/Qembed_debug");
        uint32_t space = 0;
        if (blob_type == ShaderBlobType::kSPIRV) {
            arguments.emplace_back(L"-spirv");
            arguments.emplace_back(L"-fspv-target-env=vulkan1.2");
            arguments.emplace_back(L"-fspv-extension=KHR");
            arguments.emplace_back(L"-fspv-extension=SPV_NV_mesh_shader");
            arguments.emplace_back(L"-fspv-extension=SPV_EXT_descriptor_indexing");
            arguments.emplace_back(L"-fspv-extension=SPV_EXT_shader_viewport_index_layer");
            arguments.emplace_back(L"-fspv-extension=SPV_GOOGLE_hlsl_functionality1");
            arguments.emplace_back(L"-fspv-extension=SPV_GOOGLE_user_type");
            arguments.emplace_back(L"-fvk-use-dx-layout");
            arguments.emplace_back(L"-fspv-reflect");
            space = static_cast<uint32_t>(shader.type);
        }

        arguments.emplace_back(L"-auto-binding-space");
        dynamic_arguments.emplace_back(std::to_wstring(space));
        arguments.emplace_back(dynamic_arguments.back().c_str());

        CComPtr<IDxcOperationResult> result;
        IncludeHandler include_handler(library, shader_dir);
        CComPtr<IDxcCompiler> compiler;
        dxc_support.CreateInstance(CLSID_DxcCompiler, &compiler);
        ASSERT_SUCCEEDED(compiler->Compile(source, nowide::widen(shader_file_name).c_str(), entrypoint.c_str(),
                                           target.c_str(), arguments.data(), static_cast<UINT32>(arguments.size()),
                                           defines.data(), static_cast<UINT32>(defines.size()), &include_handler,
                                           &result));

        HRESULT hr = {};
        result->GetStatus(&hr);

        if (SUCCEEDED(hr)) {
            CComPtr<IDxcBlob> dxc_blob;
            ASSERT_SUCCEEDED(result->GetResult(&dxc_blob));
            blob.assign((uint8_t*)dxc_blob->GetBufferPointer(),
                        (uint8_t*)dxc_blob->GetBufferPointer() + dxc_blob->GetBufferSize());
        } else {
#ifndef _NDEBUG
            CComPtr<IDxcBlobEncoding> errors;
            result->GetErrorBuffer(&errors);
            if (errors && errors->GetBufferSize() > 0) {
                OutputDebugStringA(reinterpret_cast<char*>(errors->GetBufferPointer()));
                std::cout << reinterpret_cast<char*>(errors->GetBufferPointer()) << std::endl;
            }
#endif
        }
    }

    return blob;
}
