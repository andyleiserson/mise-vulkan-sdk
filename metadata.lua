-- metadata.lua
-- Plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua

PLUGIN = { -- luacheck: ignore
    -- Required: Tool name (lowercase, no spaces)
    name = "vulkan-sdk",

    -- Required: Plugin version (not the tool version)
    version = "1.0.0",

    -- Required: Brief description of the tool
    description = "A mise tool plugin for the Vulkan SDK",

    -- Required: Plugin author/maintainer
    author = "andyleiserson",

    -- Optional: Repository URL for plugin updates
    updateUrl = "https://github.com/andyleiserson/mise-vulkan-sdk",

    -- Optional: Minimum mise runtime version required
    minRuntimeVersion = "0.2.0",

    -- Optional: Legacy version files this plugin can parse
    -- legacyFilenames = {
    --     ".<TOOL>-version",
    --     ".<TOOL>rc"
    -- }
}
