<#
.SYNOPSIS
WARA Runbook module

.DESCRIPTION
Enables developers to consume WARA runbook files
#>

function Read-Runbook {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$RunbookPath
    )

    # First, check to make sure the runbook actually exists...
    if (!(Test-Path $RunbookPath -PathType Leaf)) {

        # If not, fail early.
        Write-Error "[-RunbookPath]: No runbook found at [$RunbookPath]."
        $null

    } else {

        # If so, let's read this runbook!
        $runbook = @{
            Parameters = @{}
            Selectors = @{}
            Checks = @{}
            QueryOverrides = @()
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