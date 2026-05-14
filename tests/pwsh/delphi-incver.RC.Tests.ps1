# tests/pwsh/delphi-incver.RC.Tests.ps1
# Integration tests for RC target (VERSIONINFO) version incrementing.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-incver -- RC target' {

    BeforeAll {
        $script:ScriptPath   = (Resolve-Path (Join-Path $PSScriptRoot '../../source/delphi-incver.ps1')).Path
        $script:FixturesPath = (Resolve-Path (Join-Path $PSScriptRoot 'fixtures')).Path
    }

    Context '4-part RC version -- default bump (last component)' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).rc"
            Copy-Item (Join-Path $script:FixturesPath 'versioninfo-4part.rc') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'exits with code 0' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile
            $LASTEXITCODE | Should -Be 0
        }

        It 'increments the build number (last part) from 4 to 5' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '1.2.3.4'
            $result.newVersion | Should -Be '1.2.3.5'
        }

        It 'updates FILEVERSION in the file' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match 'FILEVERSION 1,2,3,5'
        }

        It 'leaves PRODUCTVERSION unchanged' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match 'PRODUCTVERSION 1,2,3,4'
        }

        It 'updates VALUE "FileVersion" string in the file' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match 'VALUE "FileVersion", "1\.2\.3\.5'
        }

        It 'leaves VALUE "ProductVersion" unchanged' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match 'VALUE "ProductVersion","1\.2\.3\.4'
        }

    }

    Context '4-part RC version -- explicit part' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).rc"
            Copy-Item (Join-Path $script:FixturesPath 'versioninfo-4part.rc') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'bumps minor and zeros patch and build' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part minor -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '1.3.0.0'
        }

        It 'bumps major and zeros minor, patch, and build' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part major -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '2.0.0.0'
        }

        It 'bumps patch and zeros build' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part patch -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '1.2.4.0'
        }

    }

    Context '3-part RC version' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).rc"
            Copy-Item (Join-Path $script:FixturesPath 'versioninfo-3part.rc') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'default bumps last component (patch) from 0 to 1' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '9.4.0'
            $result.newVersion | Should -Be '9.4.1'
        }

        It 'explicit build part on 3-part version exits non-zero' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part build -OutputFile $script:ResultFile 2>$null
            $LASTEXITCODE | Should -Not -Be 0
        }

        It 'preserves 3-part format (does not add a 4th component)' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match '(?m)FILEVERSION 9,4,1\s*$'
        }

    }

    Context '2-part RC version' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).rc"
            Copy-Item (Join-Path $script:FixturesPath 'versioninfo-2part.rc') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'default bumps last component (minor) from 7 to 8' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '3.7'
            $result.newVersion | Should -Be '3.8'
        }

        It 'bumps major and zeros minor' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part major -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '4.0'
        }

        It 'preserves 2-part format (does not add a 3rd component)' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match '(?m)FILEVERSION 3,8\s*$'
        }

        It 'explicit patch part on 2-part version exits non-zero' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part patch -OutputFile $script:ResultFile 2>$null
            $LASTEXITCODE | Should -Not -Be 0
        }

    }

    Context '1-part RC version' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).rc"
            Copy-Item (Join-Path $script:FixturesPath 'versioninfo-1part.rc') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'default bumps the sole component from 5 to 6' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '5'
            $result.newVersion | Should -Be '6'
        }

        It 'preserves 1-part format (does not add a 2nd component)' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $content = Get-Content -LiteralPath $script:TempFile -Raw
            $content | Should -Match '(?m)FILEVERSION 6\s*$'
        }

        It 'explicit minor part on 1-part version exits non-zero' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part minor -OutputFile $script:ResultFile 2>$null
            $LASTEXITCODE | Should -Not -Be 0
        }

    }

    Context 'validation' {

        It 'exits with code 3 when file does not exist' {
            & pwsh -NoProfile -File $script:ScriptPath -File 'C:\nonexistent\version.rc' 2>$null
            $LASTEXITCODE | Should -Be 3
        }

        It 'exits with code 2 when RC target is combined with SemVer style' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).rc"
            Copy-Item (Join-Path $script:FixturesPath 'versioninfo-4part.rc') $tempFile
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile -Target RC -Style SemVer 2>$null
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

    }

}
