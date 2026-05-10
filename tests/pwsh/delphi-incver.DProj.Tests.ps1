# tests/pwsh/delphi-incver.DProj.Tests.ps1
# Integration tests for DProj target (VerInfo_Keys) version incrementing.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-incver -- DProj target' {

    BeforeAll {
        $script:ScriptPath   = (Resolve-Path (Join-Path $PSScriptRoot '../../source/delphi-incver.ps1')).Path
        $script:FixturesPath = (Resolve-Path (Join-Path $PSScriptRoot 'fixtures')).Path
    }

    Context 'default bump (last component)' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            Copy-Item (Join-Path $script:FixturesPath 'sample-project.dproj') $script:TempFile
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

        It 'increments the build number (last part) in the first VerInfo_Keys' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '1.2.3.4'
            $result.newVersion | Should -Be '1.2.3.5'
        }

        It 'updates FileVersion in the Base VerInfo_Keys' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $nsMgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $nsMgr.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $baseKeys = $xml.SelectNodes('//ms:VerInfo_Keys', $nsMgr)[0].InnerText
            $baseKeys | Should -Match 'FileVersion=1\.2\.3\.5'
        }

        It 'updates FileVersion in ALL VerInfo_Keys nodes' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $nsMgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $nsMgr.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $nodes = $xml.SelectNodes('//ms:VerInfo_Keys', $nsMgr)
            foreach ($node in $nodes) {
                $node.InnerText | Should -Match 'FileVersion=1\.2\.3\.5'
            }
        }

        It 'leaves ProductVersion unchanged' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $nsMgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $nsMgr.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $nodes = $xml.SelectNodes('//ms:VerInfo_Keys', $nsMgr)
            foreach ($node in $nodes) {
                $node.InnerText | Should -Match 'ProductVersion=1\.0\.0\.0'
            }
        }

        It 'preserves other VerInfo_Keys fields' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $nsMgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $nsMgr.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $baseKeys = $xml.SelectNodes('//ms:VerInfo_Keys', $nsMgr)[0].InnerText
            $baseKeys | Should -Match 'CompanyName=TestCo'
        }

        It 'produces valid XML after update' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            { [xml](Get-Content -LiteralPath $script:TempFile -Raw) } | Should -Not -Throw
        }

    }

    Context 'explicit part' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            Copy-Item (Join-Path $script:FixturesPath 'sample-project.dproj') $script:TempFile
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

    }

    Context 'auto-detection' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            Copy-Item (Join-Path $script:FixturesPath 'sample-project.dproj') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'auto-detects DProj target from .dproj extension' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.target | Should -Be 'DProj'
        }

        It 'auto-detects WinVer style for DProj target' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.style | Should -Be 'WinVer'
        }

    }

    Context 'validation' {

        It 'exits with code 4 when no VerInfo_Keys found' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            Copy-Item (Join-Path $script:FixturesPath 'no-version-project.dproj') $tempFile
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile 2>$null
                $LASTEXITCODE | Should -Be 4
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

        It 'exits with code 2 when DProj target is combined with SemVer style' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            Copy-Item (Join-Path $script:FixturesPath 'sample-project.dproj') $tempFile
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile -Target DProj -Style SemVer 2>$null
                $LASTEXITCODE | Should -Be 2
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

    }

}
