function Read-WAFRunbookParameters() {
  param(
    [Parameter(Mandatory = $true)]
    [orderedhashtable]$RunbookSource
  )

  $parameters = @{}

  if ($RunbookSource.parameters -and $RunbookSource.parameters.Count -gt 0) {
    foreach ($parameterKey in $RunbookSource.parameters.Keys) {
      $parameters[$parameterKey] = $RunbookSource.parameters[$parameterKey]
    }
  }
  else {
    Write-Warning "Runbook defines no [parameters]."
  }

  return $parameters
}

function Read-WAFRunbookSelectors() {
  param(
    [Parameter(Mandatory = $true)]
    [orderedhashtable]$RunbookSource
  )

  $selectors = @{}

  if ($RunbookSource.selectors -and $RunbookSource.selectors.Count -gt 0) {
    foreach ($selectorKey in $RunbookSource.selectors.Keys) {
      $selectors[$selectorKey] = $RunbookSource.selectors[$selectorKey]
    }
  }
  else {
    throw "Runbook defines no [selectors]."
  }

  return $selectors
}

function Read-WAFRunbookQueryOverrides() {
  param(
    [Parameter(Mandatory = $true)]
    [orderedhashtable]$RunbookSource
  )

  $queryOverrides = @()

  if ($RunbookSource.query_overrides -and $RunbookSource.query_overrides.Count -gt 0) {
    foreach ($queryOverride in $RunbookSource.query_overrides) {
      $queryOverrides += $queryOverride
    }
  }

  return $queryOverrides
}

function Read-WAFRunbookChecks() {
  param(
    [Parameter(Mandatory = $true)]
    [orderedhashtable]$RunbookSource
  )

  $checks = @{}

  if ($RunbookSource.checks -and $RunbookSource.checks.Count -gt 0) {
    foreach ($checkKey in $RunbookSource.checks.Keys) {
      $sourceCheckConfigs = $RunbookSource.checks[$checkKey]

      $check = @{
        Configurations = @{}
      }

      foreach ($checkConfigKey in $sourceCheckConfigs.Keys) {
        $sourceCheckConfig = $sourceCheckConfigs[$checkConfigKey]

        $checkConfig = @{
          Selector    = [string]$null
          Description = [string]$null
          Parameters  = @{}
          Tags        = @()
        }

        switch ($sourceCheckConfig.GetType().Name.ToLower()) {
          'orderedhashtable' {
            $checkConfig.Selector = $sourceCheckConfig.selector
            $checkConfig.Description = $sourceCheckConfig.description

            if ($sourceCheckConfig.parameters -and $sourceCheckConfig.parameters.Count -gt 0) {
              foreach ($parameterKey in $sourceCheckConfig.parameters.Keys) {
                $checkConfig.Parameters[$parameterKey] = $sourceCheckConfig.parameters[$parameterKey]
              }
            }

            if ($sourceCheckConfig.tags -and $sourceCheckConfig.tags.Count -gt 0) {
              foreach ($tag in $sourceCheckConfig.tags) {
                $checkConfig.Tags += $tag
              }
            }
          }
          'string' {
            $checkConfig.Selector = $sourceCheckConfig
          }
          default {
            throw "Unsupported check [$checkKey/$checkConfigKey] configuration type: [$($sourceCheckConfig.GetType().Name)]"
          }
        }

        if (-not $checkConfig.Selector) {
          throw "Runbook defines a check [$checkKey/$checkConfigKey] with no selector."
        }

        $check.Configurations += [pscustomobject]$checkConfig
      }

      $checks[$checkKey] = [pscustomobject]$check
    }
  }
  else {
    throw "Runbook defines no [checks]."
  }

  return $checks
}

function Test-WAFRunbook {
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Runbook
  )

  $problems = @()

  if (-not $Runbook.Checks -or $Runbook.checks.Count -eq 0) {
    $problems += "Runbook has no [Checks] defined"
  }

  if (-not $Runbook.Selectors -or $Runbook.Selectors.Count -eq 0) {
    $problems += "Runbook has no [Selectors] defined"
  }

  if ($problems.Count -gt 0) {
    throw "Runbook is invalid: $($problems -join '; ')."
  }
}

function Read-WAFRunbook {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RunbookPath
  )

  if (-not $(Test-Path $RunbookPath -PathType Leaf)) {
    throw "Runbook file not found: [$RunbookPath]"
  }

  if (-not $(Test-Json -Path $RunbookPath)) {
    throw "Runbook file is not a valid JSON file: [$RunbookPath]"
  }

  try {
    $runbook = @{
      Parameters     = @{}
      Selectors      = @{}
      Checks         = @{}
      QueryOverrides = @()
    }
  
    $sourceJson = Get-Content -Raw $RunbookPath | ConvertFrom-Json -AsHashtable
  
    $runbook.Parameters = Read-WAFRunbookParameters -RunbookSource $sourceJson
    $runbook.Selectors = Read-WAFRunbookSelectors -RunbookSource $sourceJson
    $runbook.Checks = Read-WAFRunbookChecks -RunbookSource $sourceJson
    $runbook.QueryOverrides = Read-WAFRunbookQueryOverrides -RunbookSource $sourceJson
  
    return [pscustomobject]$runbook
  }
  catch {
    throw "Failed to read runbook [$RunbookPath]: $_"
  }
}

function Edit-WAFRunbookQuery {
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Runbook,

    [Parameter(Mandatory = $true)]
    [pscustomobject]$CheckConfiguration,

    [Parameter(Mandatory = $true)]
    [string]$Query
  )

  try {
    Test-WAFRunbook -Runbook $Runbook
    
    
  }
  catch {
    throw "Failed to edit runbook query: $_"
  }
}
