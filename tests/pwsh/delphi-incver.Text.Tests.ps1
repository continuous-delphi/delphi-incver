# tests/pwsh/delphi-incver.Text.Tests.ps1
# Integration tests for Text target version incrementing.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-incver -- Text target' {

    BeforeAll {
        $script:ScriptPath   = (Resolve-Path (Join-Path $PSScriptRoot '../../source/delphi-incver.ps1')).Path
        $script:FixturesPath = (Resolve-Path (Join-Path $PSScriptRoot 'fixtures')).Path
        $script:VersionPattern = '\$script:ToolVersion\s*=\s*''([^'']+)'''
    }

    Context 'SemVer -- default bump (last component)' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-tool.ps1') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'exits with code 0' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -OutputFile $script:ResultFile
            $LASTEXITCODE | Should -Be 0
        }

        It 'increments patch from 0.10.0 to 0.10.1' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '0.10.0'
            $result.newVersion | Should -Be '0.10.1'
        }

        It 'updates the version in the file content' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match "ToolVersion\s*=\s*'0\.10\.1'"
        }

    }

    Context 'SemVer -- explicit part' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-tool.ps1') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'bumps minor and zeros patch' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -Part minor -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '0.11.0'
        }

        It 'bumps major and zeros minor and patch' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -Part major -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '1.0.0'
        }

    }

    Context 'SemVer -- pre-release' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-semver-pre.ps1') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'default bump increments pre-release suffix' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '1.0.0-alpha.3'
            $result.newVersion | Should -Be '1.0.0-alpha.4'
        }

        It 'explicit pre-release part bumps the pre-release suffix' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -Part pre-release -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '1.0.0-alpha.4'
        }

        It 'bumping patch clears the pre-release tag' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -Part patch -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '1.0.1'
        }

    }

    Context 'Text target with WinVer style' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-tool.ps1') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'uses WinVer parsing when style is explicitly WinVer' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Pattern $script:VersionPattern -Style WinVer -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.style | Should -Be 'WinVer'
            $result.newVersion | Should -Be '0.10.1'
        }

    }

    Context 'validation' {

        It 'exits with code 2 when Text target has no pattern' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-tool.ps1') $tempFile
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile -Target Text 2>$null
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'exits with code 4 when pattern does not match' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-tool.ps1') $tempFile
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile -Pattern 'NoMatch_(\d+)' 2>$null
                $LASTEXITCODE | Should -Be 4
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'exits with code 2 when pre-release part is used with WinVer style' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).ps1"
            Copy-Item (Join-Path $script:FixturesPath 'sample-tool.ps1') $tempFile
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile -Pattern $script:VersionPattern -Style WinVer -Part pre-release 2>$null
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

    }

}
