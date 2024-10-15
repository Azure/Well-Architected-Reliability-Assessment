[CmdletBinding()]
param (
    [String]$moduleName
)
# Determine the base path based on the environment
if ($env:GITHUB_WORKSPACE) {
    # Running in GitHub Actions
    $basePath = "./src"
    $baseDocsPath = "./docs"
} else {
    # Running locally
    $basePath = "$PSScriptRoot/../../src"
    $baseDocsPath = "$PSScriptRoot/../../docs"
}



if($moduleName)
{
    $moduleDirectories = Get-ChildItem -Path "$basePath/modules/wara/" -Directory | Where-Object { $_.Name -eq $moduleName }
}
else{
    # Grab directories
    $moduleDirectories = Get-ChildItem -Path "$basePath/modules/wara/" -Directory
}

foreach ($moduleDir in $moduleDirectories) {
    $modulePath = "$($moduleDir.FullName)/$($moduleDir.Name).psm1"
    $docsPath = "$baseDocsPath/$($moduleDir.Name)"
    Import-Module $modulePath -force
    New-MarkdownHelp -Module $moduleDir.Name -OutputFolder $docsPath -WithModulePage
    Update-MarkdownHelpModule -Path $docsPath -RefreshModulePage
}