--- Configures environment variables for the installed tool
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook
--- @param ctx {path: string, runtimeVersion: string, sdkInfo: table} Context
--- @return table[] List of environment variable definitions
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.path
    -- local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    -- local version = sdkInfo.version

    -- Basic configuration (minimum required for most tools)
    -- This adds the bin directory to PATH so the tool can be executed

    local sdkPath = mainPath .. "/x86_64"
    return {
        {
            key = "VULKAN_SDK",
            value = sdkPath,
        },
        {
            key = "PATH",
            value = sdkPath .. "/bin",
        },
        {
            key = "LD_LIBRARY_PATH",
            value = sdkPath .. "/lib",
        },
        {
            key = "VK_ADD_LAYER_PATH",
            value = sdkPath .. "/share/vulkan/explicit_layer.d",
        },
        {
            key = "PKG_CONFIG_PATH",
            value = sdkPath .. "/share/pkgconfig",
        },
        {
            key = "PKG_CONFIG_PATH",
            value = sdkPath .. "/lib/pkgconfig",
        },
    }

    -- Example: Tool-specific environment variables
    --[[
    return {
        {
            key = "<TOOL>_HOME",
            value = mainPath,
        },
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
        -- Multiple PATH entries are automatically merged
        {
            key = "PATH",
            value = mainPath .. "/scripts",
        },
    }
    --]]

    -- Example: Library paths for compiled tools
    --[[
    return {
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
        {
            key = "LD_LIBRARY_PATH",
            value = mainPath .. "/lib",
        },
        {
            key = "PKG_CONFIG_PATH",
            value = mainPath .. "/lib/pkgconfig",
        },
    }
    --]]

    -- Example: Platform-specific configuration
    --[[
    local env_vars = {
        {
            key = "PATH",
            value = mainPath .. "/bin",
        },
    }

    -- RUNTIME object is provided by mise/vfox
    if RUNTIME.osType == "Darwin" then
        table.insert(env_vars, {
            key = "DYLD_LIBRARY_PATH",
            value = mainPath .. "/lib",
        })
    elseif RUNTIME.osType == "Linux" then
        table.insert(env_vars, {
            key = "LD_LIBRARY_PATH",
            value = mainPath .. "/lib",
        })
    end
    -- Windows doesn't use these library path variables

    return env_vars
    --]]
end
