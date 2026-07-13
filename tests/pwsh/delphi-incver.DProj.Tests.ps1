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

        # sample-project.dproj carries distinct keys (Base 1.2.3.4, derived
        # 1.2.3.244); the baseline is the maximum across keys (1.2.3.244), not the
        # first in document order (issue #9).
        It 'increments the maximum baseline across VerInfo_Keys nodes' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '1.2.3.244'
            $result.newVersion | Should -Be '1.2.3.245'
        }

        It 'updates FileVersion in the Base VerInfo_Keys' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $nsMgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $nsMgr.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $baseKeys = $xml.SelectNodes('//ms:VerInfo_Keys', $nsMgr)[0].InnerText
            $baseKeys | Should -Match 'FileVersion=1\.2\.3\.245'
        }

        It 'updates FileVersion in ALL VerInfo_Keys nodes' {
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $nsMgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $nsMgr.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $nodes = $xml.SelectNodes('//ms:VerInfo_Keys', $nsMgr)
            foreach ($node in $nodes) {
                $node.InnerText | Should -Match 'FileVersion=1\.2\.3\.245'
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

    # -------------------------------------------------------------------------
    # Issue #8: discrete VerInfo_* elements must be kept in sync with the
    # FileVersion key so the RAD Studio Version Info dialog cannot silently
    # revert a bump on Save.
    # -------------------------------------------------------------------------
    Context 'discrete VerInfo sync (issue #8)' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            Copy-Item (Join-Path $script:FixturesPath 'mismatch-project.dproj') $script:TempFile
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $script:Xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $script:Ns = [System.Xml.XmlNamespaceManager]::new($script:Xml.NameTable)
            $script:Ns.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            $script:Raw = Get-Content -LiteralPath $script:TempFile -Raw
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'updates FileVersion in every VerInfo_Keys node' {
            foreach ($n in $script:Xml.SelectNodes('//ms:VerInfo_Keys', $script:Ns)) {
                $n.InnerText | Should -Match 'FileVersion=1\.2\.3\.5'
            }
        }

        It 'leaves ProductVersion unchanged in every VerInfo_Keys node' {
            foreach ($n in $script:Xml.SelectNodes('//ms:VerInfo_Keys', $script:Ns)) {
                $n.InnerText | Should -Match 'ProductVersion=9\.0\.0\.0'
            }
        }

        It 'sets every discrete element to the bumped four-part version' {
            foreach ($n in $script:Xml.SelectNodes('//ms:VerInfo_MajorVer', $script:Ns)) { $n.InnerText | Should -Be '1' }
            foreach ($n in $script:Xml.SelectNodes('//ms:VerInfo_MinorVer', $script:Ns)) { $n.InnerText | Should -Be '2' }
            foreach ($n in $script:Xml.SelectNodes('//ms:VerInfo_Release',  $script:Ns)) { $n.InnerText | Should -Be '3' }
            foreach ($n in $script:Xml.SelectNodes('//ms:VerInfo_Build',    $script:Ns)) { $n.InnerText | Should -Be '5' }
        }

        It 'creates the four discrete elements in the group that lacked them' {
            # Both keyed PropertyGroups must now carry each discrete element.
            $script:Xml.SelectNodes('//ms:VerInfo_MajorVer', $script:Ns).Count | Should -Be 2
            $script:Xml.SelectNodes('//ms:VerInfo_MinorVer', $script:Ns).Count | Should -Be 2
            $script:Xml.SelectNodes('//ms:VerInfo_Release',  $script:Ns).Count | Should -Be 2
            $script:Xml.SelectNodes('//ms:VerInfo_Build',    $script:Ns).Count | Should -Be 2
        }

        It 'inserts created discrete elements in alphabetical order (matches IDE serialization)' {
            $cfg = $script:Raw.Substring($script:Raw.IndexOf('Cfg_2_Win32'))
            $order = 'VerInfo_Build', 'VerInfo_IncludeVerInfo', 'VerInfo_Keys', 'VerInfo_Locale', 'VerInfo_MajorVer', 'VerInfo_MinorVer', 'VerInfo_Release'
            $positions = $order | ForEach-Object { $cfg.IndexOf("<$_>") }
            foreach ($p in $positions) { $p | Should -BeGreaterThan (-1) }
            $sorted = $positions | Sort-Object
            "$positions" | Should -Be "$sorted"
        }

        It 'does not add discrete elements to a PropertyGroup that has no VerInfo_Keys' {
            $noKeys = $script:Xml.SelectSingleNode('//ms:PropertyGroup[ms:ProjectGuid]', $script:Ns)
            $noKeys.SelectNodes('ms:VerInfo_MajorVer', $script:Ns).Count | Should -Be 0
        }

        It 'reports discreteVersion in the JSON output' {
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion      | Should -Be '1.2.3.5'
            $result.discreteVersion | Should -Be '1.2.3.5'
        }

    }

    Context 'discrete sync -- version widths and explicit parts' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'zero-pads discrete elements to four values regardless of key width' -ForEach @(
            @{ Ver = '1.2.4'; NewStr = '1.2.5'; Disc = '1.2.5.0' }
            @{ Ver = '1.3';   NewStr = '1.4';   Disc = '1.4.0.0' }
            @{ Ver = '7';     NewStr = '8';     Disc = '8.0.0.0' }
        ) {
            $content = @"
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
        <VerInfo_Keys>FileVersion=$Ver;ProductVersion=9.0.0.0</VerInfo_Keys>
    </PropertyGroup>
</Project>
"@
            Set-Content -LiteralPath $script:TempFile -Value $content -NoNewline
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion      | Should -Be $NewStr
            $result.discreteVersion | Should -Be $Disc

            $xml = [xml](Get-Content -LiteralPath $script:TempFile -Raw)
            $ns = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
            $ns.AddNamespace('ms', 'http://schemas.microsoft.com/developer/msbuild/2003')
            # FileVersion string keeps its original width
            $xml.SelectSingleNode('//ms:VerInfo_Keys', $ns).InnerText | Should -Match "FileVersion=$([regex]::Escape($NewStr));"
            # discrete elements are the four zero-padded values
            $expected = $Disc -split '\.'
            $xml.SelectSingleNode('//ms:VerInfo_MajorVer', $ns).InnerText | Should -Be $expected[0]
            $xml.SelectSingleNode('//ms:VerInfo_MinorVer', $ns).InnerText | Should -Be $expected[1]
            $xml.SelectSingleNode('//ms:VerInfo_Release',  $ns).InnerText | Should -Be $expected[2]
            $xml.SelectSingleNode('//ms:VerInfo_Build',    $ns).InnerText | Should -Be $expected[3]
        }

        It 'flows zeroing through to discrete elements on -Part minor' {
            $content = @"
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
        <VerInfo_Keys>FileVersion=1.2.3.4;ProductVersion=9.0.0.0</VerInfo_Keys>
    </PropertyGroup>
</Project>
"@
            Set-Content -LiteralPath $script:TempFile -Value $content -NoNewline
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part minor -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion      | Should -Be '1.3.0.0'
            $result.discreteVersion | Should -Be '1.3.0.0'
        }

    }

    Context 'discrete sync -- file fidelity' {

        It 'preserves BOM, CRLF line endings, and indentation' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            $lines = @(
                '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">'
                '    <PropertyGroup>'
                '        <VerInfo_Keys>FileVersion=1.2.3.4;ProductVersion=9.0.0.0</VerInfo_Keys>'
                '        <VerInfo_Locale>1033</VerInfo_Locale>'
                '    </PropertyGroup>'
                '</Project>'
            )
            $text = ($lines -join "`r`n") + "`r`n"
            [System.IO.File]::WriteAllText($tempFile, $text, [System.Text.UTF8Encoding]::new($true))
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile 2>$null
                $LASTEXITCODE | Should -Be 0

                $bytes = [System.IO.File]::ReadAllBytes($tempFile)
                # BOM preserved
                $bytes[0] | Should -Be 0xEF
                $bytes[1] | Should -Be 0xBB
                $bytes[2] | Should -Be 0xBF

                $after = [System.IO.File]::ReadAllText($tempFile)
                # every LF is part of a CRLF (no lone LF introduced, no CRLF stripped)
                ([regex]::Matches($after, "`n")).Count | Should -Be ([regex]::Matches($after, "`r`n")).Count
                # indentation not reflowed: untouched line byte-identical, groups at 4 spaces
                $after | Should -Match '        <VerInfo_Locale>1033</VerInfo_Locale>'
                $after | Should -Match '(?m)^    <PropertyGroup>'
                # the bump did land
                $after | Should -Match 'FileVersion=1\.2\.3\.5'
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

    }

    Context 'discrete sync -- error handling' {

        It 'fails and leaves the file unmodified when a discrete element is non-numeric' {
            $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            $content = @"
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
        <VerInfo_Keys>FileVersion=1.2.3.4;ProductVersion=9.0.0.0</VerInfo_Keys>
        <VerInfo_Build>abc</VerInfo_Build>
    </PropertyGroup>
</Project>
"@
            Set-Content -LiteralPath $tempFile -Value $content -NoNewline
            $before = Get-Content -LiteralPath $tempFile -Raw
            try {
                & pwsh -NoProfile -File $script:ScriptPath -File $tempFile 2>$null
                $LASTEXITCODE | Should -Not -Be 0
                (Get-Content -LiteralPath $tempFile -Raw) | Should -BeExactly $before
            }
            finally {
                Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
            }
        }

    }

    # -------------------------------------------------------------------------
    # Issue #9: the baseline is the maximum FileVersion across all VerInfo_Keys
    # nodes, not the first in document order -- so the Base group's 1.0.0.0
    # placeholder can no longer regress the effective version.
    # -------------------------------------------------------------------------
    Context 'baseline selection -- max across keys (issue #9)' {

        BeforeEach {
            $script:TempFile = Join-Path ([System.IO.Path]::GetTempPath()) "incver-test-$([guid]::NewGuid()).dproj"
            $script:ResultFile = [System.IO.Path]::GetTempFileName()
        }

        AfterEach {
            Remove-Item -LiteralPath $script:TempFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $script:ResultFile -Force -ErrorAction SilentlyContinue
        }

        It 'bumps the derived version, not the Base placeholder' {
            Copy-Item (Join-Path $script:FixturesPath 'placeholder-project.dproj') $script:TempFile
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '1.2.3.4'
            $result.newVersion | Should -Be '1.2.3.5'

            $raw = Get-Content -LiteralPath $script:TempFile -Raw
            # every key unified to the bumped baseline; the placeholder never wins
            [regex]::Matches($raw, 'FileVersion=1\.2\.3\.5(?![\d.])').Count | Should -Be 2
            $raw | Should -Not -Match 'FileVersion=1\.0\.0\.1'
        }

        It 'emits an informational notice naming the distinct values and the chosen baseline' {
            Copy-Item (Join-Path $script:FixturesPath 'placeholder-project.dproj') $script:TempFile
            $out = (& pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile 2>$null) -join "`n"
            $out | Should -Match 'Multiple FileVersion values found'
            $out | Should -Match '1\.0\.0\.0'
            $out | Should -Match '1\.2\.3\.4'
            $out | Should -Match 'baseline 1\.2\.3\.4'
        }

        It 'bumps uniform keys and emits no mismatch notice' {
            Copy-Item (Join-Path $script:FixturesPath 'uniform-project.dproj') $script:TempFile
            $out = (& pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null) -join "`n"
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '2.1.0.0'
            $result.newVersion | Should -Be '2.1.0.1'

            $raw = Get-Content -LiteralPath $script:TempFile -Raw
            [regex]::Matches($raw, 'FileVersion=2\.1\.0\.1').Count | Should -Be 2
            $out | Should -Not -Match 'Multiple FileVersion values found'
        }

        It 'compares with zero-padding and unifies keys to the baseline width' {
            # baseline is 1.2.3 (> 1.0.0.0 padded); the 4-part placeholder key is
            # narrowed to the 3-part baseline when all keys are unified.
            $content = @"
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup Condition="'`$(Base_Win32)'!=''">
        <VerInfo_Keys>FileVersion=1.0.0.0;ProductVersion=1.0.0.0</VerInfo_Keys>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Cfg_1_Win32)'!=''">
        <VerInfo_Keys>FileVersion=1.2.3;ProductVersion=9.0.0.0</VerInfo_Keys>
    </PropertyGroup>
</Project>
"@
            Set-Content -LiteralPath $script:TempFile -Value $content -NoNewline
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.oldVersion | Should -Be '1.2.3'
            $result.newVersion | Should -Be '1.2.4'

            $raw = Get-Content -LiteralPath $script:TempFile -Raw
            [regex]::Matches($raw, 'FileVersion=1\.2\.4(?![\d.])').Count | Should -Be 2
        }

        It 'applies -Part to the derived baseline' {
            Copy-Item (Join-Path $script:FixturesPath 'placeholder-project.dproj') $script:TempFile
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile -Part minor -OutputFile $script:ResultFile 2>$null
            $result = Get-Content -LiteralPath $script:ResultFile -Raw | ConvertFrom-Json
            $result.newVersion | Should -Be '1.3.0.0'

            $raw = Get-Content -LiteralPath $script:TempFile -Raw
            [regex]::Matches($raw, 'FileVersion=1\.3\.0\.0').Count | Should -Be 2
        }

        It 'fails and leaves the file unmodified when a FileVersion cannot be parsed' {
            $content = @"
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup Condition="'`$(Base_Win32)'!=''">
        <VerInfo_Keys>FileVersion=banana;ProductVersion=1.0.0.0</VerInfo_Keys>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Cfg_1_Win32)'!=''">
        <VerInfo_Keys>FileVersion=1.2.3.4;ProductVersion=9.0.0.0</VerInfo_Keys>
    </PropertyGroup>
</Project>
"@
            Set-Content -LiteralPath $script:TempFile -Value $content -NoNewline
            $before = Get-Content -LiteralPath $script:TempFile -Raw
            & pwsh -NoProfile -File $script:ScriptPath -File $script:TempFile 2>$null
            $LASTEXITCODE | Should -Not -Be 0
            (Get-Content -LiteralPath $script:TempFile -Raw) | Should -BeExactly $before
        }

    }

}
