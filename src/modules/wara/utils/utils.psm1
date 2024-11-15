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
function Import-WAFConfigFileData() {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ConfigFile
  )
  # Read the file content and store it in a variable
  $filecontent, $linetable, $objarray, $count, $start, $stop, $configsection = $null
  $filepath = (Resolve-Path -Path $configfile).Path
  $filecontent = (Get-content $filepath).trim().tolower()

  # Create an array to store the line number of each section
  $linetable = @()
  $objarray = [ordered]@{}

  $filecontent = $filecontent | Where-Object { $_ -ne "" -and $_ -notlike "*#*" }

  #Remove empty space.
  foreach ($line in $filecontent) {
    $index = $filecontent.IndexOf($line)
    if ($line -match "^\[([^\]]+)\]$" -and ($filecontent[$index + 1] -match "^\[([^\]]+)\]$" -or [string]::IsNullOrEmpty($filecontent[$index + 1]))) {
      # Set this line to empty because the next line is a section as well.
      # This is to avoid the section name being added to the object since it has no parameters.
      # This is because if we were to keep the note-property it would mess up logic for determining if a section is empty.
      # Powershell will return $true on an emtpy note property - Because the property exists.
      $filecontent[$index] = ""
    }
  }

  #Remove empty space again.
  $filecontent = $filecontent | Where-Object { $_ -ne "" -and $_ -notlike "*#*" }

  # Iterate through the file content and store the line number of each section
  foreach ($line in $filecontent) {
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.startswith("#")) {
      #Get the Index of the current line
      $index = $filecontent.IndexOf($line)
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

    if ($linetable.count -eq $count + 1) {
      $stop = $filecontent.count - 1
    }
    else {
      $stop = $linetable[$count + 1] - 1
    }
        

    # Extract the section content
    $configsection = $filecontent[$start..$stop]

    # Add the section content to the object array
    $objarray += @{$name = $configsection }

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
    [GUID]$TenantID,
    [ValidateSet('AzureCloud', 'AzureChinaCloud', 'AzureGermanCloud', 'AzureUSGovernment')]
    [string]$AzureEnvironment = 'AzureCloud'
  )

  # Connect To Azure Tenant
  if (-not (Get-AzContext)) {
    Connect-AzAccount -Tenant $TenantID -WarningAction SilentlyContinue -Environment $AzureEnvironment
  }
}

Function Test-WAFTagPattern {
  param (
    [string[]]$InputValue
  )
  $pattern = '^[^<>&%\\?/]+=~[^<>&%\\?/]+$|[^<>&%\\?/]+!~[^<>&%\\?/]+$'

  $allMatch = $true

  foreach ($value in $InputValue) {
    if ($value -notmatch $pattern) {
      $allMatch = $false
      throw "Tag pattern [$value] is not valid."
      break
    }
  }
  return $allMatch
}

function Test-WAFResourceGroupId {
  param (
    [string[]]$InputValue
  )
  $pattern = '\/subscriptions\/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\/resourceGroups\/[a-zA-Z0-9._-]+'

  $allMatch = $true

  foreach ($value in $InputValue) {
    if ($value -notmatch $pattern) {
      $allMatch = $false
      throw "Resource Group ID [$value] is not valid."
      break
    }
  }

  return $allMatch
}

Function Test-WAFSubscriptionId {
  param (
    [string[]]$InputValue
  )
  $pattern = '\/subscriptions\/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
  $allMatch = $true

  foreach ($value in $InputValue) {
    if ($value -notmatch $pattern) {
      $allMatch = $false
      throw "Subscription ID [$value] is not valid."
      break
    }
  }
  return $allMatch
}

function Test-WAFIsGuid {
  param (
    [Parameter(Mandatory = $true)]
    $StringGuid
  )
  $ObjectGuid = [System.Guid]::Empty
  if (-not [System.Guid]::TryParse($StringGuid, [ref]$ObjectGuid)) {
    throw "The provided string [$StringGuid] is not a valid GUID."
  }
  return $true
}

function Test-WAFScriptParameters {
  $IsValid = $true

  if ($RunbookFile) {

    if (!(Test-Path $RunbookFile -PathType Leaf)) {
      Write-Host "Runbook file (-RunbookFile) not found: [$RunbookFile]" -ForegroundColor Red
      $IsValid = $false
    }

    if ($ConfigFile) {
      Write-Host "Runbook file (-RunbookFile) and configuration file (-ConfigFile) cannot be used together." -ForegroundColor Red
      $IsValid = $false
    }

    if (!($SubscriptionIds)) {
      Write-Host "Subscription ID(s) (-SubscriptionIds) is required when using a runbook file (-RunbookFile)." -ForegroundColor Red
      $IsValid = $false
    }

    if ($ResourceGroups -or $Tags) {
      Write-Host "Resource group(s) (-ResourceGroups) and tags (-Tags) cannot be used with a runbook file (-RunbookFile)." -ForegroundColor Red
      $IsValid = $false
    }

  }
  else {

    if ($UseImplicitRunbookSelectors) {
      Write-Host "Implicit runbook selectors (-UseImplicitRunbookSelectors) can only be used with a runbook file (-RunbookFile)." -ForegroundColor Red
      $IsValid = $false
    }

    if ($ConfigFile) {

      if (!(Test-Path $ConfigFile -PathType Leaf)) {
        Write-Host "Configuration file (-ConfigFile) not found: [$ConfigFile]" -ForegroundColor Red
        $IsValid = $false
      }

      if ($SubscriptionIds -or $ResourceGroups -or $Tags) {
        Write-Host "Configuration file (-ConfigFile) and [Subscription ID(s) (-SubscriptionIds), resource group(s) (-ResourceGroups), or tags (-Tags)] cannot be used together." -ForegroundColor Red
        $IsValid = $false
      }

      if ($TenantId) {
        Write-Host "Tenant ID (-TenantId) cannot be used with a configuration file (-ConfigFile). Include tenant ID in the [tenantid] section of the config file." -ForegroundColor Red
        $IsValid = $false
      }

    }
    else {

      if (!($TenantId)) {
        Write-Host "Tenant ID (-TenantId) is required." -ForegroundColor Red
        $IsValid = $false
      }

      if (!($SubscriptionIds) -and !($ResourceGroups)) {
        Write-Host "Subscription ID(s) (-SubscriptionIds) or resource group(s) (-ResourceGroups) are required." -ForegroundColor Red
        $IsValid = $false
      }
    }
  }

  return $IsValid
}