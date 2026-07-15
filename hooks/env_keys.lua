--- Configures environment variables for the installed Vulkan SDK.
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook
---
--- These mirror the variables set by the SDK's own `setup-env.sh` /
--- `setenv` scripts. mise merges repeated keys (e.g. PATH, PKG_CONFIG_PATH,
--- VK_ICD_FILENAMES) into a single path-list value.
--- @param ctx EnvKeysCtx
--- @return EnvKey[]
function PLUGIN:EnvKeys(ctx)
    local vulkan = require("vulkan")

    local plat = vulkan.platform()

    -- Root of the usable SDK (the directory containing bin/lib/include/share).
    -- On Windows the installer targets the install path directly; on Linux and
    -- macOS the payload lives under a platform sub-directory.
    local sdkPath = ctx.path
    if plat.sdkSubdir ~= "" then
        sdkPath = ctx.path .. "/" .. plat.sdkSubdir
    end

    if RUNTIME.osType == "darwin" then
        return {
            { key = "VULKAN_SDK", value = sdkPath },
            { key = "PATH", value = sdkPath .. "/bin" },
            { key = "DYLD_LIBRARY_PATH", value = sdkPath .. "/lib" },
            { key = "VK_ADD_LAYER_PATH", value = sdkPath .. "/share/vulkan/explicit_layer.d" },
            { key = "PKG_CONFIG_PATH", value = sdkPath .. "/share/pkgconfig" },
            { key = "PKG_CONFIG_PATH", value = sdkPath .. "/lib/pkgconfig" },
            -- macOS has no system Vulkan driver, so point the loader at the
            -- SDK-provided ICDs (MoltenVK and kosmickrisp).
            { key = "VK_ICD_FILENAMES", value = sdkPath .. "/share/vulkan/icd.d/MoltenVK_icd.json" },
            { key = "VK_DRIVER_FILES", value = sdkPath .. "/share/vulkan/icd.d/MoltenVK_icd.json" },
            { key = "VK_ICD_FILENAMES", value = sdkPath .. "/share/vulkan/icd.d/libkosmickrisp_icd.json" },
            { key = "VK_DRIVER_FILES", value = sdkPath .. "/share/vulkan/icd.d/libkosmickrisp_icd.json" },
        }
    elseif RUNTIME.osType == "windows" then
        return {
            { key = "VULKAN_SDK", value = sdkPath },
            { key = "PATH", value = sdkPath .. "/Bin" },
            { key = "VK_ADD_LAYER_PATH", value = sdkPath .. "/Bin" },
        }
    else
        -- Linux. The loader uses the system-installed ICD, so no VK_ICD_*.
        return {
            { key = "VULKAN_SDK", value = sdkPath },
            { key = "PATH", value = sdkPath .. "/bin" },
            { key = "LD_LIBRARY_PATH", value = sdkPath .. "/lib" },
            { key = "VK_ADD_LAYER_PATH", value = sdkPath .. "/share/vulkan/explicit_layer.d" },
            { key = "PKG_CONFIG_PATH", value = sdkPath .. "/lib/pkgconfig" },
        }
    end
end
