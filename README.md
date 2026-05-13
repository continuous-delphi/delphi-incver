# delphi-incver

![delphi-clean logo](https://continuous-delphi.github.io/assets/logos/delphi-incver-480x270.png)

[![Delphi](https://img.shields.io/badge/delphi-red)](https://www.embarcadero.com/products/delphi)
[![CI](https://github.com/continuous-delphi/delphi-incver/actions/workflows/ci.yml/badge.svg)](https://github.com/continuous-delphi/delphi-incver/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/continuous-delphi/delphi-incver?display_name=release)](https://github.com/continuous-delphi/delphi-incver/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/continuous-delphi/delphi-incver)
[![Continuous Delphi](https://img.shields.io/badge/org-continuous--delphi-red)](https://github.com/continuous-delphi)

PowerShell tool to increment version numbers in RC and Text source files, supporting `WinVer` and `SemVer` styles.

## Overview

`delphi-incver` is a PowerShell utility that increments version numbers in
 `.RC` (VERSIONINFO) and text source files. It supports `WinVer`
(numeric `N.N.N.N`) and `SemVer` ([semver.org](https://semver.org)) styles.

Designed for use as a standalone command or as a bundled tool inside
[delphi-powershell-ci](https://github.com/continuous-delphi/delphi-powershell-ci).

---

## Running the Tool

If `delphi-incver` is on your PATH:

```powershell
delphi-incver -File src/versioninfo.rc
```

Otherwise, run it directly:

```powershell
pwsh -File .\source\delphi-incver.ps1 -File src/versioninfo.rc
# or
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\source\delphi-incver.ps1 -File src/versioninfo.rc
```

## PowerShell Compatibility

Runs on the widely available Windows PowerShell 5.1 (`powershell.exe`)
and the newer PowerShell 7+ (`pwsh`).

---

## Features

- Increment version numbers in RC (VERSIONINFO), DProj, or text source files
- Auto-detect target type from file extension (`.rc` -> RC, `.dproj` -> DProj, else Text)
- Auto-detect version style from target (RC/DProj -> WinVer, else SemVer)
- Bump any component: `major`, `minor`, `patch`, `build`, or `pre-release`
- Default bump increments the last component of whatever width exists
- Bumping a component zeros everything to its right
- Preserves the original version width (never adds or removes components)
- RC target updates both FileVersion locations in a single pass
- DProj target updates `FileVersion` in all `VerInfo_Keys` elements
- Text target uses a user-supplied regex pattern with a capture group
- Structured JSON output via `-OutputFile` for tool integration

---

## -File

Path to the file containing the version to increment. Required.

```powershell
delphi-incver -File src/versioninfo.rc
delphi-incver -File src/MyApp.dproj
delphi-incver -File source/mytool.ps1 -Pattern '\$script:ToolVersion\s*=\s*''([^'']+)'''
```

---

## -Target

File type: `RC`, `DProj`, or `Text`. When omitted, auto-detected from the
file extension.

| Extension | Target |
|-----------|--------|
| `.rc`     | RC     |
| `.dproj`  | DProj  |
| anything else | Text |

```powershell
delphi-incver -File version.rc -Target RC
delphi-incver -File MyApp.dproj -Target DProj
delphi-incver -File version.txt -Target Text -Pattern '(\d+\.\d+\.\d+)'
```

---

## -Style

Version format: `WinVer` or `SemVer`. When omitted, auto-detected from the target.

| Target | Default Style |
|--------|---------------|
| RC     | WinVer        |
| DProj  | WinVer        |
| Text   | SemVer        |

### WinVer

Strictly numeric with 1 to 4 dot-separated components: `N`, `N.N`, `N.N.N`,
or `N.N.N.N`. Used by Windows VERSIONINFO resources and Delphi project files.

### SemVer

Follows [semver.org](https://semver.org): `MAJOR.MINOR.PATCH` with optional
pre-release (`-alpha.1`) and build metadata (`+build.42`) suffixes.

### Valid Combinations

| Target | WinVer | SemVer |
|--------|--------|--------|
| RC     | Yes (default) | Error |
| DProj  | Yes (default) | Error |
| Text   | Yes    | Yes (default) |

```powershell
delphi-incver -File ver.rc -Style WinVer
delphi-incver -File ver.txt -Style SemVer -Pattern '(\d+\.\d+\.\d+)'
```

---

## -Part

Which version component to increment: `major`, `minor`, `patch`, `build`,
or `pre-release`.

When omitted, bumps the **last component** of the existing version regardless
of width:

| Source       | Default bump result |
|--------------|---------------------|
| `1.0.0.4`   | `1.0.0.5`           |
| `9.4.0`     | `9.4.1`             |
| `1.3`       | `1.4`               |
| `7`         | `8`                 |

When explicit, the source version must have enough parts. For example,
`-Part build` on a 3-part version is an error.

Bumping a component zeros everything to its right:

```text
1.2.3.4  -Part minor  ->  1.3.0.0
1.2.3.4  -Part major  ->  2.0.0.0
0.10.0   -Part minor  ->  0.11.0
```

### Pre-release (SemVer only)

`-Part pre-release` increments the numeric suffix of the pre-release tag:

```text
1.0.0-alpha.3  ->  1.0.0-alpha.4
1.0.0-beta     ->  1.0.0-beta.1
```

Bumping `major`, `minor`, or `patch` clears the pre-release tag:

```text
1.0.0-alpha.3  -Part patch  ->  1.0.1
```

```powershell
delphi-incver -File ver.rc -Part minor
delphi-incver -File ver.rc -Part build
delphi-incver -File tool.ps1 -Pattern '...' -Part pre-release
```

---

## -Pattern

Regex pattern with a capture group around the version string. **Required for
Text targets.** Not used for RC or DProj targets.

The first capture group identifies the version substring to parse and replace.
Everything outside the capture group is preserved as-is.

```powershell
# PowerShell script version variable
delphi-incver -File tool.ps1 -Pattern '\$script:ToolVersion\s*=\s*''([^'']+)'''

# Generic version in a text file
delphi-incver -File VERSION.txt -Pattern '^(\d+\.\d+\.\d+)$'

# Version in a YAML file
delphi-incver -File pubspec.yaml -Pattern 'version:\s*(\S+)'
```

### Quoting Tips

Patterns containing `$` must use single quotes in PowerShell to prevent
variable interpolation. Embed literal single quotes by doubling them (`''`).

---

## -OutputFile

Path to write a structured JSON result file. Used for tool integration
(e.g., by `delphi-powershell-ci` to capture old/new version strings).

```json
{
  "file": "src/versioninfo.rc",
  "target": "RC",
  "style": "WinVer",
  "part": "build",
  "oldVersion": "1.2.3.4",
  "newVersion": "1.2.3.5"
}
```

```powershell
delphi-incver -File ver.rc -OutputFile result.json
```

---

## RC Target Behavior

For RC files, `delphi-incver` updates both FileVersion locations in a
single pass. ProductVersion is left unchanged (it often follows a
different lifecycle).

```text
FILEVERSION 1,2,3,4               ->  FILEVERSION 1,2,3,5
PRODUCTVERSION 1,2,3,4            ->  (unchanged)
VALUE "FileVersion", "1.2.3.4"    ->  VALUE "FileVersion", "1.2.3.5"
VALUE "ProductVersion", "1.2.3.4" ->  (unchanged)
```

Supports 1 to 4 part versions. The part count is never changed.

---

## DProj Target Behavior

For `.dproj` files, `delphi-incver` updates the `FileVersion` value inside
every `VerInfo_Keys` element across all `PropertyGroup` sections. This
follows the same approach as the
[Embarcadero blog post](https://blogs.embarcadero.com/change-dproj-file-and-product-version/)
on programmatic .dproj version changes.

- Reads the current version from `FileVersion=` in the first `VerInfo_Keys`
- Increments it using WinVer logic
- Writes the new `FileVersion=` to ALL `VerInfo_Keys` nodes
- `ProductVersion` is left unchanged (it often follows a different lifecycle)
- Discrete elements (`VerInfo_MajorVer`, `VerInfo_Build`, etc.) are left
  alone -- the IDE resyncs them when the project is opened

No `-Pattern` is needed for DProj targets.

```powershell
delphi-incver -File src/MyApp.dproj
delphi-incver -File src/MyApp.dproj -Part minor
```

---

## Exit Codes

```text
  0 = success: version incremented and file updated
  1 = unexpected error
  2 = invalid arguments (bad target/style combo, missing pattern, etc.)
  3 = file not found or unreadable
  4 = version pattern not found in file
  5 = version increment failed (e.g. explicit -Part build on a 3-part version)
```

---

## Examples

Bump the build number in an RC file (default: last component):

```powershell
delphi-incver -File src/versioninfo.rc
```

Bump the minor version and zero patch/build:

```powershell
delphi-incver -File src/versioninfo.rc -Part minor
```

Bump the FileVersion in a Delphi .dproj file:

```powershell
delphi-incver -File src/MyApp.dproj
```

Bump a SemVer version in a PowerShell script:

```powershell
delphi-incver -File src/mytool.ps1 -Pattern '\$script:ToolVersion\s*=\s*''([^'']+)'''
```

Bump a pre-release tag:

```powershell
delphi-incver -File src/mytool.ps1 -Pattern '\$script:ToolVersion\s*=\s*''([^'']+)''' -Part pre-release
```

Use WinVer style on a text file:

```powershell
delphi-incver -File VERSION.txt -Style WinVer -Pattern '^(\d+\.\d+\.\d+\.\d+)$'
```

---

## Running Tests

Requires PowerShell 7+, Pester 5.7+, and PSScriptAnalyzer.

```powershell
./tests/run-tests.ps1
```

---


## Continuous-Delphi

This tool is part of the [Continuous-Delphi](https://github.com/continuous-delphi)
ecosystem, focused on strengthening Delphi's continued success.

![continuous-delphi logo](https://continuous-delphi.github.io/assets/logos/continuous-delphi-480x270.png)
