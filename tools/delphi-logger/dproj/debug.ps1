Import-Module ContinuousDelphi.Logger
Initialize-CDLogger -Source 'delphi-incver' -OutputMode Silent -MinimumLevel Trace -CaptureOutput $true

& "$PSScriptRoot\..\..\..\source\delphi-incver.ps1" `
    -File "$PSScriptRoot\..\..\..\tests\pwsh\fixtures\sample-project.dproj" `
    -Target DProj `
    -Part build

. "$PSScriptRoot\..\Write-CDDebugLog.ps1"
