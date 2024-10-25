<#
.SYNOPSIS
Reads a runbook

.DESCRIPTION
The Read-WAFRunbook function converts a WAF runbook file to a corresponding hashtable
#>
function Read-WAFRunbook {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RunbookPath
  )

  # Check that the file actually exists
  if (-not $(Test-Path $RunbookPath -PathType Leaf)) {
    throw "Runbook file not found: [$RunbookPath]"
  }

  $runbook = @{
    Parameters     = @{}
    Selectors      = @{}
    Checks         = @{}
    QueryOverrides = @()
  }

  # Read the runbook JSON
  $fileJson = Get-Content -Raw $RunbookPath | ConvertFrom-Json -AsHashtable



  if ($fileJson.parameters -and $fileJson.parameters.Count -gt 0) {
    # Read parameters
    foreach ($parameterKey in $fileJson.parameters.Keys) {
      $runbook.Parameters[$parameterKey] = $fileJson.parameters[$parameterKey]
    }
  }
  else {
    # It's odd that there's no parameters
    Write-Warning "Runbook [$RunbookPath] defines no [parameters]."
  }

  if ($fileJson.selectors) {
    # Read selectors
    foreach ($selectorKey in $fileJson.selectors.Keys) {
      $runbook.Selectors[$selectorKey] = $fileJson.selectors[$selectorKey]
    }
  }
  else {
    # Checks are required and checks require selectors.
    # Therefore, selectors are required.
    throw "Runbook [$RunbookPath] defines no [selectors]. [selectors] are required."
  }

        
  # Read the runbook JSON
  $runbookJson = Get-Content -Raw $RunbookPath | ConvertFrom-Json

  # Try to load parameters
  $runbookJson.parameters.PSObject.Properties | ForEach-Object {
    $runbook.Parameters[$_.Name] = $_.Value
  }

  # Try to load selectors
  $runbookJson.selectors.PSObject.Properties | ForEach-Object {
    $runbook.Selectors[$_.Name.ToLower()] = $_.Value
  }

  # Try to load checks
  $runbookJson.checks.PSObject.Properties | ForEach-Object {
    $runbook.Checks[$_.Name.ToLower()] = $_.Value
  }

  # Try to load query overrides
  $runbookJson.query_overrides | ForEach-Object {
    $runbook.QueryOverrides += [string]$_
  }

  return [pscustomobject]$runbook
}
}
#>
