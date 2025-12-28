# Graft

Dependency management for Make with first-class support for patching and overlays.

## Why Graft?

Existing dependency managers (vcpkg, Conan, CMake FetchContent) treat patching as an afterthought. When you need to fix a bug in a dependency before upstream accepts your PR, you're stuck maintaining a fork.

Graft makes patching a core workflow:

- **Patch files** are tracked in your repo—small, auditable diffs
- **Overlays** let you replace specific files via symlinks
- **Patch regeneration** with `make <dep>_patch` after you modify the extracted source
- **Caching** preserves your patches across rebuilds

### Compared to alternatives

| Feature | Graft | vcpkg | Conan | FetchContent |
|---------|-------|-------|-------|--------------|
| Patching workflow | First-class | Port overlay | Awkward | PATCH_COMMAND |
| Overlay support | Yes | No | No | No |
| Patch regeneration | `make X_patch` | Manual | Manual | Manual |
| Language agnostic | Yes | C/C++ | C/C++ | CMake |
| Ecosystem lock-in | None | vcpkg | Conan | CMake |
| Dependencies | make, curl, git | vcpkg | pip, conan | cmake |

## Quick Start

1. Copy `graft.mk` to your project
2. Set up your Makefile:

```makefile
b := bin           # Output directory
DL := .cache       # Download cache

include graft.mk

# Define a dependency
FMT_COMMIT := 10.2.1
FMT_GIT_URL := https://github.com/fmtlib/fmt.git
$(eval $(call GEN_DOWNLOAD_RECIPE,FMT))

# Use it
my_app: main.cpp $(FMT_TGT)
	g++ -o $@ $< -I$(FMT_DIR)/include

# Generate directory rules
$(foreach V,$(sort $(DIRS)),$(eval $(call MK_DIR,$V)))
```

3. Run `make` - dependencies are fetched, cached, and extracted automatically.

## Features

### Fetching

Three source types supported:

```makefile
# Git repository (most common)
LIB_COMMIT := v1.0.0
LIB_GIT_URL := https://github.com/owner/lib.git

# Direct tarball
LIB_TAR_URL := https://example.com/lib-1.0.0.tar.gz

# Zip archive
LIB_ZIP_URL := https://example.com/lib-1.0.0.zip
```

### Building Before Cache

Run build commands before the dependency is cached. Useful for compiled libraries:

```makefile
FMT_COMMIT := 10.2.1
FMT_GIT_URL := https://github.com/fmtlib/fmt.git
FMT_PRE_UNPACK = cmake -S $(FMT_TMP) -B build && cmake --build build
$(eval $(call GEN_DOWNLOAD_RECIPE,FMT))

FMT_LIB := $(FMT_DIR)/build/libfmt.a
```

The build runs in `$(NAME_TMP)` (default: `/tmp/name/`) and the result is tarred and cached.

### Post-Extraction Hooks

Run commands after extraction:

```makefile
LIB_POST_UNPACK = chmod +x $(LIB_DIR)/configure
```

### Patching

Apply unified diff patches after extraction:

```makefile
LIB_PATCH := patches/lib-fix-bug.patch
```

**Regenerating patches:** After modifying files in `$(LIB_DIR)`:

```bash
make lib_patch
```

This diffs against the original and updates your patch file.

### Overlays

Symlink local files over the dependency. Useful for replacing headers or config:

```makefile
LIB_OVERLAY := overlays/lib/
```

Files in `overlays/lib/` are symlinked into `$(LIB_DIR)`. The overlay directory structure mirrors the dependency.

### Dependencies Between Libraries

Use `_EXTRA` to ensure one dependency is built before another:

```makefile
CMAKE_TAR_URL := https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0-linux-x86_64.tar.gz
$(eval $(call GEN_DOWNLOAD_RECIPE,CMAKE))

FMT_COMMIT := 10.2.1
FMT_GIT_URL := https://github.com/fmtlib/fmt.git
FMT_PRE_UNPACK = $(CMAKE_DIR)/bin/cmake -S $(FMT_TMP) -B build
FMT_EXTRA := $(CMAKE_TGT)
$(eval $(call GEN_DOWNLOAD_RECIPE,FMT))
```

### Custom Target Files

By default, `README.md` is used to detect if a dependency is extracted. Override:

```makefile
CMAKE_TGT := $(CMAKE_DIR)/bin/cmake
```

## API Reference

### Required Setup

| Variable | Description |
|----------|-------------|
| `b` | Output directory for extracted dependencies |
| `DL` | Cache directory for downloaded archives |
| `DIRS` | Append to this for automatic directory creation |

### Per-Dependency Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `NAME_GIT_URL` | One of three | Git repository URL |
| `NAME_TAR_URL` | source types | Direct tarball URL |
| `NAME_ZIP_URL` | required | Zip archive URL |
| `NAME_COMMIT` | If GIT_URL | Git tag, branch, or commit hash |
| `NAME_TGT` | No | Target file to check (default: `$DIR/README.md`) |
| `NAME_DIR` | No | Install directory (default: `$b/name`) |
| `NAME_TMP` | No | Temp build directory (default: `/tmp/name`) |
| `NAME_PRE_UNPACK` | No | Command after clone, before cache |
| `NAME_POST_UNPACK` | No | Command after extraction |
| `NAME_PATCH` | No | Patch file path |
| `NAME_OVERLAY` | No | Overlay directory path |
| `NAME_EXTRA` | No | Prerequisite targets |

### Generated Variables

After `$(eval $(call GEN_DOWNLOAD_RECIPE,NAME))`:

| Variable | Description |
|----------|-------------|
| `NAME_DIR` | Path to extracted dependency |
| `NAME_TGT` | Target file path |
| `NAME_TAR` | Cached tarball path |

### Generated Targets

| Target | Description |
|--------|-------------|
| `name_tgt` | Phony target to build dependency |
| `name_patch` | Regenerate patch file (if `NAME_PATCH` set) |

## Examples

See `examples/cpp/` for a comprehensive C++ project using:
- Header-only libraries (nlohmann/json, cpp-httplib)
- Compiled libraries (fmt, Catch2, yaml-cpp, SQLiteCpp)
- CMake as a downloaded tool dependency
- Aurora Units for type-safe units

## Testing

```bash
cd tests && make
```

Individual tests:
```bash
cd tests && make test_git_clone
```

## Requirements

- GNU Make
- curl
- git
- tar (with gzip support)
- unzip (for ZIP_URL only)
- patch (for PATCH only)

## License

MIT License. See [LICENSE](LICENSE).
