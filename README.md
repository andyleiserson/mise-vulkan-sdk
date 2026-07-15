# mise-vulkan-sdk

A [mise](https://mise.jdx.dev) tool plugin (vfox-style Lua hooks) for installing
the [LunarG Vulkan SDK](https://vulkan.lunarg.com/).

It queries LunarG's
[Version Query and Download API](https://vulkan.lunarg.com/content/view/latest-sdk-version-api)
for available versions, downloads the requested SDK, verifies its SHA-256, and
wires up the environment (`VULKAN_SDK`, `PATH`, library/layer paths, …) so the
toolchain (`glslang`, `spirv-*`, `vulkaninfo`, …) is ready to use.

## Supported platforms

| OS       | Arch  | LunarG platform | Artifact              | Install method                          |
| -------- | ----- | --------------- | --------------------- | --------------------------------------- |
| macOS    | any   | `mac`           | `.zip` (universal)    | Extract, run bundled Qt IFW installer   |
| Linux    | x86_64| `linux`         | `.tar.xz`             | Extract in place                        |
| Windows  | x64   | `windows`       | `.exe`                | Run Qt IFW installer                    |
| Windows  | ARM64 | `warm`          | `.exe`                | Run Qt IFW installer                    |

Notes:

- LunarG only publishes an **x86_64** Linux SDK; other Linux architectures are
  rejected with a clear error.
- The macOS SDK is a single universal build (Intel + Apple Silicon).
- On macOS/Windows the download is a Qt Installer Framework installer that is
  driven headlessly (`--accept-licenses --default-answer --confirm-command install`).
  On macOS it installs into `<install>/macOS`; on Windows it installs into the
  install root directly. On Linux the tarball is simply extracted (payload lives
  under `<install>/x86_64`).

## Usage

```bash
# Install a specific version
mise install vulkan-sdk@1.4.350.1

# Install and activate the latest
mise use vulkan-sdk@latest

# List available versions
mise ls-remote vulkan-sdk
```

Once activated, `VULKAN_SDK` and the relevant `PATH` / loader variables are set
automatically in the mise environment.

## How it works

The plugin defines the standard vfox hooks:

- `hooks/available.lua` — lists versions from
  `https://vulkan.lunarg.com/sdk/versions/<platform>.json`.
- `hooks/pre_install.lua` — resolves the download URL and fetches the SHA-256
  from `https://sdk.lunarg.com/sdk/sha/...`.
- `hooks/post_install.lua` — runs the platform installer (macOS/Windows); a
  no-op on Linux.
- `hooks/env_keys.lua` — exports the SDK environment variables.

Platform detection and all URL construction live in the shared
`lib/vulkan.lua` module.

## Development

```bash
# Link this checkout as a plugin
mise plugin link --force vulkan-sdk .

# Run linting (stylua + lua-language-server + actionlint via hk)
mise run lint

# Run the end-to-end test (installs the latest SDK and exercises glslang)
mise run test

# Full CI suite
mise run ci
```

Enable debug output with `MISE_DEBUG=1 mise install vulkan-sdk@latest`.

CI (`.github/workflows/ci.yml`) runs the lint + test suite on Linux and macOS.
The Windows install flow mirrors macOS but is not exercised in CI.

## License

MIT
