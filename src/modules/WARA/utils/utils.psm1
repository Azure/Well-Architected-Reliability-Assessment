function Import-WAFConfigFileData($file){
    # Read the file content and store it in a variable
    $filecontent = (Get-content $file).trim().tolower()

    # Create an array to store the line number of each section
    $linetable = @()
    $objarray = @{}

    # Iterate through the file content and store the line number of each section
    Foreach($line in $filecontent){
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.startswith("#")){
            # If the line is a section, store the line number
            if ($line -match "^\[([^\]]+)\]$") {
                # Store the section name and line number. Remove the brackets from the section name
                $linetable += $filecontent.indexof($line)

            }
        }
    }

    # Iterate through the line numbers and extract the section content
    $count = 0
    foreach($entry in $linetable){

        # Get the section name
        $name = $filecontent[$entry]
        # Remove the brackets from the section name
        $name = $name.replace("[","").replace("]","")

        # Get the start and stop line numbers for the section content
        # If the section is the last one, set the stop line number to the end of the file
        $start = $entry + 1
        if($count -eq ($linetable.length-1)){
            $stop = $filecontent.length - 1
        }
        else{
            $stop = $linetable[$count+1] - 2
        }

        # Extract the section content
        $configsection = $filecontent[$start..$stop]

        # Add the section content to the object array
        $objarray += @{$Name=$configsection}

        # Increment the count
        $count++
    }

    # Return the object array and cast to pscustomobject
    return [pscustomobject]$objarray

  }

  function Connect-WAFAzure 
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        [Parameter(Mandatory = $true)]
        [string[]]$SubscriptionIds,
        [ValidateSet('AzureCloud', 'AzureChinaCloud', 'AzureGermanCloud', 'AzureUSGovernment')]
        [string]$AzureEnvironment = 'AzureCloud'
    )

    # Connect To Azure Tenant
    If(-not (Get-AzContext))
    {
        Connect-AzAccount -Tenant $TenantID -WarningAction SilentlyContinue -Environment $AzureEnvironment
    }
}

