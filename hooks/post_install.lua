--- Performs additional setup after the download has been placed/extracted.
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook
--- @param ctx PostInstallCtx
function PLUGIN:PostInstall(ctx)
    local sdkInfo = ctx.sdkInfo[PLUGIN.name]
    local path = sdkInfo.path
    local version = sdkInfo.version

    if RUNTIME.osType == "darwin" then
        -- mise extracts the downloaded zip directly into the install path
        -- (`path`), stripping the top-level `vulkansdk-macOS-<v>.app/`
        -- component, so the .app bundle's `Contents/` lands directly under
        -- `path`. Move the unpacked installer to a temporary directory, then
        -- run it to install into `path`.
        local installer = "Contents/MacOS/vulkansdk-macOS-" .. version

        local result = os.execute(
            string.format(
                "set -e; "
                    .. "tmp=$(mktemp -d); "
                    .. 'mv %q/* "$tmp"/; '
                    .. '"$tmp"/%s --root %q --accept-licenses --default-answer --confirm-command install com.lunarg.vulkan.core com.lunarg.vulkan.kosmic copy_only=1; '
                    .. 'rm -rf "$tmp"',
                path,
                installer,
                path
            )
        )
        if result ~= 0 and result ~= true then
            error("Failed to install " .. PLUGIN.name)
        end
    elseif RUNTIME.osType == "windows" then
        -- The Windows download is the Qt Installer Framework installer itself
        -- (a bare .exe, not an archive), placed by mise at
        -- `<path>/vulkan_sdk.exe`. Drive it headlessly to install the default
        -- component set directly into `path`, mirroring the macOS flow.
        local installer = path .. "\\vulkan_sdk.exe"

        local result = os.execute(
            string.format(
                '"%s" --root "%s" --accept-licenses --default-answer --confirm-command install',
                installer,
                path
            )
        )
        if result ~= 0 and result ~= true then
            error("Failed to install " .. PLUGIN.name)
        end
    end

    -- Linux: the tarball is extracted in place (mise strips the leading
    -- `<version>/` component, leaving `<path>/x86_64/...`) and needs no
    -- post-processing.
end
