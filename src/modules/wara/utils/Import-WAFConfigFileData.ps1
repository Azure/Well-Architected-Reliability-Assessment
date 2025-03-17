<#
.SYNOPSIS
    Imports configuration data from a file.

.DESCRIPTION
    The `Import-WAFConfigFileData` function reads the content of a configuration file, extracts sections, and returns the data as a `PSCustomObject`. The configuration file should have sections defined by square brackets `[SectionName]` and key-value pairs within each section.

.PARAMETER ConfigFile
    The path to the configuration file.

.INPUTS
    System.String. The function accepts a string representing the path to the configuration file.

.OUTPUTS
    System.Management.Automation.PSCustomObject. Returns a custom object containing the configuration data.

.EXAMPLE
    PS> $configData = Import-WAFConfigFileData -ConfigFile "C:\config\settings.txt"

    This example imports configuration data from the specified file.

.EXAMPLE
    PS> Import-WAFConfigFileData -ConfigFile "config.txt"

    This example imports configuration data from 'config.txt' in the current directory.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Import-WAFConfigFileData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $ConfigFile
    )

    # Read the file content and store it in a variable
    $filecontent, $linetable, $objarray, $count, $start, $stop, $configsection = $null
    $filepath = (Resolve-Path -Path $configfile).Path
    $filecontent = (Get-content $filepath).trim().tolower()

    # Create an array to store the line number of each section
    $linetable = @()
    $objarray = [ordered]@{}

    $filecontent = $filecontent | Where-Object { $_ -ne '' -and $_ -notlike '*#*' }

    #Remove empty space.
    foreach ($line in $filecontent) {
        $index = $filecontent.IndexOf($line)
        if ($line -match '^\[([^\]]+)\]$' -and ($filecontent[$index + 1] -match '^\[([^\]]+)\]$' -or [string]::IsNullOrEmpty($filecontent[$index + 1]))) {
            $filecontent[$index] = ''
        }
    }

    #Remove empty space again.
    $filecontent = $filecontent | Where-Object { $_ -ne '' -and $_ -notlike '*#*' }

    # Iterate through the file content and store the line number of each section
    foreach ($line in $filecontent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.startswith('#')) {
            $index = $filecontent.IndexOf($line)
            if ($line -match '^\[([^\]]+)\]$') {
                $linetable += $filecontent.indexof($line)
            }
        }
    }

    # Iterate through the line numbers and extract the section content
    $count = 0
    foreach ($entry in $linetable) {
        $name = $filecontent[$entry]
        $name = $name.replace('[', '').replace(']', '')
        $start = $entry + 1

        if ($linetable.count -eq $count + 1) {
            $stop = $filecontent.count - 1
        }
        else {
            $stop = $linetable[$count + 1] - 1
        }

        $configsection = $filecontent[$start..$stop]
        $objarray += @{$name = $configsection }
        $count++
    }

    return [PSCustomObject]$objarray
}
