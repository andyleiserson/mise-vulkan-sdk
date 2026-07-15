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
        -- component set into `path`, mirroring the macOS flow.
        --
        -- QtIFW refuses to install into a non-empty directory (with
        -- `--default-answer` it declines the overwrite prompt and aborts), but
        -- mise unpacks the installer *into* `path`. So, like the macOS branch's
        -- mktemp-and-move, relocate the installer into a temporary subdirectory
        -- first, leaving `path` empty. The temp dir lives under the tool's
        -- install root (`parent`, the `installs/<tool>` dir) — the same volume
        -- as `path` — so the os.rename can't fail cross-volume; os.rename is a
        -- direct syscall (no shell), so it handles spaces.
        local parent = path:gsub("[\\/][^\\/]+$", "")
        local tmp = parent .. "\\.vulkan-sdk-installer"
        local installer = tmp .. "\\vulkan_sdk.exe"

        os.execute("mkdir " .. tmp)
        local ok, err = os.rename(path .. "\\vulkan_sdk.exe", installer)
        if not ok then
            error("Failed to relocate the Vulkan SDK installer: " .. tostring(err))
        end

        -- `copy_only=1` makes the LunarG installer just lay down files instead
        -- of doing system integration (registry/ICD registration), which needs
        -- elevation and would fail in this headless, non-admin context. We
        -- install the default component set (kosmickrisp is macOS-only, and
        -- without it the explicit `core` component is unnecessary here).
        --
        -- The installer and install root are absolute paths passed WITHOUT
        -- quotes. mise runs the command as a single `cmd /C <string>` arg via
        -- Rust's std::process::Command (crates/vfox/src/lua_mod/cmd.rs), whose
        -- `\"`-escaping of embedded quotes is mis-parsed by cmd.exe — a quoted
        -- `"C:\..."` reaches the tool as `\C:\...` — so quoting breaks it.
        --
        -- FIXME: this breaks if `path` contains spaces (e.g. a username with a
        -- space). QtIFW rejects a relative `--root` ("the installation path
        -- cannot be relative"), so the `cwd`-relative trick the wgpu-mesa plugin
        -- uses isn't available here. mise install paths under %LOCALAPPDATA% are
        -- conventionally space-free, so this is fine in practice for now.
        local result = os.execute(
            installer
                .. " --root "
                .. path
                .. " --accept-licenses --default-answer --confirm-command install copy_only=1"
        )

        -- Remove the temporary installer directory regardless of outcome.
        os.execute("rmdir /s /q " .. tmp)

        if result ~= 0 and result ~= true then
            error("Failed to install " .. PLUGIN.name)
        end
    end

    -- Linux: the tarball is extracted in place (mise strips the leading
    -- `<version>/` component, leaving `<path>/x86_64/...`) and needs no
    -- post-processing.
end
