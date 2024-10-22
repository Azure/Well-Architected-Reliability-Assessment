<#
.SYNOPSIS
Imports configuration data from a file.

.DESCRIPTION
The Import-WAFConfigFileData function reads the content of a configuration file, extracts sections, and returns the data as a PSCustomObject.

.PARAMETER file
The path to the configuration file.

.OUTPUTS
Returns a PSCustomObject containing the configuration data.

.EXAMPLE
PS> $configData = Import-WAFConfigFileData -file "config.txt"
#>
function Import-WAFConfigFileData($file) {
    # Read the file content and store it in a variable
    $filecontent,$linetable,$objarray,$count,$start,$stop,$configsection = $null
    $filecontent = (Get-content $file).trim().tolower()

    # Create an array to store the line number of each section
    $linetable = @()
    $objarray = [ordered]@{}

    $filecontent = $filecontent | Where-Object {$_ -ne ""}

    # Iterate through the file content and store the line number of each section
    foreach ($line in $filecontent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.startswith("#")) {
            # If the line is a section, store the line number
            if ($line -match "^\[([^\]]+)\]$") {
                # Store the section name and line number. Remove the brackets from the section name
                $linetable += $filecontent.indexof($line)
            }
        }
    }

    # Iterate through the line numbers and extract the section content
    $count = 0
    foreach ($entry in $linetable) {
        # Get the section name
        $name = $filecontent[$entry]
        # Remove the brackets from the section name
        $name = $name.replace("[", "").replace("]", "")

        # Get the start and stop line numbers for the section content
        # If the section is the last one, set the stop line number to the end of the file
        $start = $entry + 1

        if($linetable.count -eq $count+1){
            $stop = $filecontent.count - 1
        }else{
            $stop = $linetable[$count + 1] -1
        }
        

        # Extract the section content
        $configsection = $filecontent[$start..$stop]

        # Add the section content to the object array
        $objarray += @{$name = $configsection}

        # Increment the count
        $count++
    }

    # Return the object array and cast to PSCustomObject
    return [pscustomobject]$objarray
}

<#
.SYNOPSIS
Connects to an Azure tenant.

.DESCRIPTION
The Connect-WAFAzure function connects to an Azure tenant using the provided Tenant ID and Subscription IDs.

.PARAMETER TenantID
The Tenant ID to connect to.

.PARAMETER SubscriptionIds
An array of Subscription IDs to scope the connection.

.PARAMETER AzureEnvironment
The Azure environment to connect to. Defaults to 'AzureCloud'.

.OUTPUTS
None.

.EXAMPLE
PS> Connect-WAFAzure -TenantID "your-tenant-id" -SubscriptionIds @("sub1", "sub2") -AzureEnvironment "AzureCloud"
#>
function Connect-WAFAzure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        [Parameter(Mandatory = $true)]
        [string[]]$SubscriptionIds,
        [ValidateSet('AzureCloud', 'AzureChinaCloud', 'AzureGermanCloud', 'AzureUSGovernment')]
        [string]$AzureEnvironment = 'AzureCloud'
    )

    # Connect To Azure Tenant
    if (-not (Get-AzContext)) {
        Connect-AzAccount -Tenant $TenantID -WarningAction SilentlyContinue -Environment $AzureEnvironment
    }
}

<#
.SYNOPSIS
Imports JSON data from a file.

.DESCRIPTION
The Import-WAFAPRLJSON function reads the content of a JSON file, converts it to a PowerShell object, and returns it.

.PARAMETER file
The path to the JSON file.

.OUTPUTS
Returns a PowerShell object containing the JSON data.

.EXAMPLE
PS> $jsonData = Import-WAFAPRLJSON -file "data.json"
#>
function Import-WAFAPRLJSON {
    param (
        [Parameter(Mandatory = $true)]
        [string]$file
    )

    # Validate file path, read content and convert to JSON
    $return = (Test-Path $file) ? (Get-Content $file -Raw | ConvertFrom-Json -Depth 10) : ("Path does not exist")

    # Return the converted JSON object
    return $return
}