--- Shared helpers for the Vulkan SDK plugin.
---
--- Centralises everything that depends on the LunarG "Vulkan SDK Version Query
--- and Download API" (https://vulkan.lunarg.com/content/view/latest-sdk-version-api)
--- so the individual hooks stay small.

local M = {}

--- Host that answers version-query requests (versions list, latest, etc.).
M.QUERY_HOST = "https://vulkan.lunarg.com"

--- Host that serves the actual downloads and SHA hashes.
M.DOWNLOAD_HOST = "https://sdk.lunarg.com"

--- Describes the current platform in terms the LunarG API understands.
---
--- @class VulkanPlatform
--- @field name string LunarG platform id: "linux", "mac", "windows", "warm"
--- @field ext string Download file extension: "tar.xz", "zip" or "exe"
--- @field archive boolean Whether the download is an archive mise extracts
--- @field sdkSubdir string Sub-path under the install root holding bin/lib/...

--- Resolve the LunarG platform for the current runtime.
---
--- RUNTIME.osType is "darwin", "linux" or "windows"; RUNTIME.archType is
--- "amd64", "arm64", etc.
--- @return VulkanPlatform
function M.platform()
    local osType = RUNTIME.osType
    local arch = RUNTIME.archType

    if osType == "darwin" then
        -- The macOS SDK is a single universal build (Intel + Apple Silicon).
        -- It ships as a .zip containing a GUI installer .app that we drive
        -- headlessly; the installer lays the SDK out under "<root>/macOS".
        return { name = "mac", ext = "zip", archive = true, sdkSubdir = "macOS" }
    elseif osType == "linux" then
        -- LunarG only publishes an x86_64 Linux SDK.
        if arch ~= "amd64" then
            error(
                "The Vulkan SDK is only available for x86_64 Linux (architecture '"
                    .. tostring(arch)
                    .. "' is not supported)"
            )
        end
        -- The tarball extracts to "<version>/x86_64/...". mise strips the
        -- leading "<version>/" component, leaving "<root>/x86_64/...".
        return { name = "linux", ext = "tar.xz", archive = true, sdkSubdir = "x86_64" }
    elseif osType == "windows" then
        -- Like macOS, Windows ships a Qt Installer Framework installer, but as
        -- a bare .exe (not inside an archive). It installs the SDK directly
        -- under the given root, so there is no extra sub-directory.
        if arch == "arm64" then
            return { name = "warm", ext = "exe", archive = false, sdkSubdir = "" }
        end
        return { name = "windows", ext = "exe", archive = false, sdkSubdir = "" }
    else
        error("Unsupported operating system: " .. tostring(osType))
    end
end

--- URL returning the JSON array of available versions for a platform.
--- @param plat VulkanPlatform
--- @return string
function M.versions_url(plat)
    return string.format("%s/sdk/versions/%s.json", M.QUERY_HOST, plat.name)
end

--- Generic (version-less) download filename, e.g. "vulkan_sdk.tar.xz".
--- @param plat VulkanPlatform
--- @return string
function M.download_filename(plat)
    return "vulkan_sdk." .. plat.ext
end

--- Download URL for a specific version.
--- @param plat VulkanPlatform
--- @param version string
--- @return string
function M.download_url(plat, version)
    return string.format("%s/sdk/download/%s/%s/%s", M.DOWNLOAD_HOST, version, plat.name, M.download_filename(plat))
end

--- URL returning JSON metadata (including the SHA-256) for a download.
--- @param plat VulkanPlatform
--- @param version string
--- @return string
function M.sha_url(plat, version)
    return string.format("%s/sdk/sha/%s/%s/%s.json", M.DOWNLOAD_HOST, version, plat.name, M.download_filename(plat))
end

--- Perform a GET request, erroring on transport failure or non-200 status.
--- @param url string
--- @return string body
function M.http_get(url)
    local http = require("http")
    local resp, err = http.get({ url = url })
    if err ~= nil then
        error("Request to " .. url .. " failed: " .. err)
    end
    if resp.status_code ~= 200 then
        error("Request to " .. url .. " returned status " .. resp.status_code)
    end
    return resp.body
end

--- Fetch the list of available versions (newest first) for a platform.
--- @param plat VulkanPlatform
--- @return string[]
function M.fetch_versions(plat)
    local json = require("json")
    local body = M.http_get(M.versions_url(plat))
    local versions = json.decode(body)
    if type(versions) ~= "table" then
        error("Unexpected response from " .. M.versions_url(plat))
    end
    return versions
end

--- Fetch the SHA-256 of a version's download, or nil when it is unavailable
--- (older SDKs may not have a hash on record).
--- @param plat VulkanPlatform
--- @param version string
--- @return string|nil
function M.fetch_sha256(plat, version)
    local http = require("http")
    local json = require("json")
    local resp, err = http.get({ url = M.sha_url(plat, version) })
    if err ~= nil or resp.status_code ~= 200 then
        return nil
    end
    local ok, data = pcall(json.decode, resp.body)
    if not ok or type(data) ~= "table" or type(data.sha) ~= "string" or data.sha == "" then
        return nil
    end
    return data.sha
end

return M
