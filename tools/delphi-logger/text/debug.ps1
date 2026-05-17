Import-Module ContinuousDelphi.Logger
Initialize-CDLogger -Source 'delphi-incver' -OutputMode Silent -MinimumLevel Trace -CaptureOutput $true

& "$PSScriptRoot\..\..\..\source\delphi-incver.ps1" `
    -File "$PSScriptRoot\..\..\..\tests\pwsh\fixtures\sample-tool.ps1" `
    -Target Text `
    -Style SemVer `
    -Part patch `
    -Pattern '\$script:ToolVersion\s*=\s*''([^'']+)'''

. "$PSScriptRoot\..\Write-CDDebugLog.ps1"
