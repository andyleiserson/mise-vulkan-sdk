--- Returns the list of available Vulkan SDK versions for the current platform.
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#available-hook
--- @param ctx AvailableCtx
--- @return AvailableVersion[]
function PLUGIN:Available(ctx)
    local vulkan = require("vulkan")

    local plat = vulkan.platform()
    local versions = vulkan.fetch_versions(plat)

    -- The API returns versions sorted newest to oldest.
    local result = {}
    for i, version in ipairs(versions) do
        table.insert(result, {
            version = version,
            note = i == 1 and "latest" or nil,
        })
    end

    return result
end
