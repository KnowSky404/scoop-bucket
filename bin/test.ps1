#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.1' }
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

$config = New-PesterConfiguration -Hashtable @{
    Run = @{ Path = "$PSScriptRoot/.."; PassThru = $true }
    Output = @{ Verbosity = 'Detailed' }
}
# Validate every manifest, including on documentation-only dispatches.
$env:CI = 'false'
$result = Invoke-Pester -Configuration $config
exit $result.FailedCount
