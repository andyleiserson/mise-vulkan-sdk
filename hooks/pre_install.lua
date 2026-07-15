--- Returns download information for a specific Vulkan SDK version.
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook
--- @param ctx PreInstallCtx
--- @return PreInstallResult
function PLUGIN:PreInstall(ctx)
    local vulkan = require("vulkan")

    local version = ctx.version
    local plat = vulkan.platform()

    -- Best-effort checksum verification. Older SDKs may not have a recorded
    -- hash, in which case fetch_sha256 returns nil and mise skips the check.
    local sha256 = vulkan.fetch_sha256(plat, version)

    return {
        version = version,
        url = vulkan.download_url(plat, version),
        sha256 = sha256,
    }
end
