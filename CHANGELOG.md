# `delphi-incver` Changelog

All notable changes to this project will be documented in this file.

---
## [1.5.0] - 2026-07-13

- DProj target now selects the baseline as the maximum `FileVersion` across all
  `VerInfo_Keys` nodes instead of the first in document order, so the Base
  group's `1.0.0.0` placeholder can no longer regress the effective version. A
  bump never decreases any `FileVersion` entry; mismatched keys emit an
  informational notice.
[#9](https://github.com/continuous-delphi/delphi-incver/issues/9)

## [1.4.0] - 2026-07-13

- DProj target now keeps the discrete `VerInfo_MajorVer`/`MinorVer`/`Release`/`Build`
  elements in sync with the `FileVersion` key (update where present, create where
  absent) so the RAD Studio Version Info dialog can no longer silently revert a
  bump on Save. Edits preserve the file's BOM, line endings, and indentation.
[#8](https://github.com/continuous-delphi/delphi-incver/issues/8)

## [1.3.0] - 2026-05-18
- Reverted delphi-logger changes. Reconsidered - noise greater than value

## [1.2.0] - 2026-05-17

- Code tidy up, minor doc/script tweaks
[#7](https://github.com/continuous-delphi/delphi-incver/issues/7)

## [1.1.0] - 2026-05-14

- Added debug log tooling in /tools/delphi-logger

## [1.0.0] - 2026-05-14

- Support for `delphi-logger` added (opt-in structural logging for debug
purposes.) [#6](https://github.com/continuous-delphi/delphi-incver/issues/6)

- RC target now updates only FileVersion; ProductVersion is left unchanged
  (aligns with DProj target behavior)

## [0.2.0] - 2026-05-09

- initial release with `WinVer` and `SemVer` formats targeting `RC`, `DProj`, and `Text` files

<br />
<br />

### `delphi-incver` - a developer tool from Continuous Delphi

![continuous-delphi logo](https://continuous-delphi.github.io/assets/logos/continuous-delphi-480x270.png)

https://github.com/continuous-delphi
