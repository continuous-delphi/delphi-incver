Import-Module ContinuousDelphi.Logger
Initialize-CDLogger -Source 'delphi-incver' -OutputMode Silent -MinimumLevel Trace -CaptureOutput $true

& "$PSScriptRoot\..\..\..\source\delphi-incver.ps1" `
    -File "$PSScriptRoot\..\..\..\tests\pwsh\fixtures\versioninfo-4part.rc" `
    -Target RC `
    -Part build

. "$PSScriptRoot\..\Write-CDDebugLog.ps1"
