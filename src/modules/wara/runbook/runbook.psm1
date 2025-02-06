using module ../utils/utils.psd1

$waraRepoUrl = "https://github.com/azure/well-architected-reliability-assessment"

class Recommendation {
    [string] $AprlGuid
    [string] $RecommendationTypeId
    [string] $RecommendationMetadataState
    [string] $RecommendationControl
    [string] $LongDescription
    [string] $Description
    [string] $PotentialBenefits
    [string] $RecommendationResourceType
    [string] $RecommendationImpact
    [string] $Query

    [string[]] $Tags

    [bool] $PgVerified
    [bool] $AutomationAvailable
}

class RunbookCheckQuery {
    [string] $CheckSetName
    [string] $CheckName
    [string] $Query

    [Recommendation] $Recommendation
}

class RunbookCheck {
    [string] $GroupingName
    [string] $SelectorName

    [hashtable] $Parameters = @{}

    [string[]] $Tags = @()
}

class RunbookCheckSet {
    [hashtable] $Checks = @{}
}

class Runbook {
    [string[]] $QueryPaths = @()

    [hashtable] $Parameters = @{}
    [hashtable] $Variables = @{}
    [hashtable] $Selectors = @{}
    [hashtable] $Groupings = @{}
    [hashtable] $CheckSets = @{}

    static [string] $Schema = @"
{
  "title": "Runbook",
  "description": "A well-architected reliability assessment (WARA) runbook (see $waraRepoUrl)",
  "type": "object",
  "properties": {
    "parameters": {
      "type": "object"
    },
    "variables": {
      "type": "object"
    },
    "groupings": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    },
    "selectors": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    },
    "checks": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "additionalProperties": {
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "selector": {
                  "type": "string"
                },
                "grouping": {
                  "type": "string"
                },
                "parameters": {
                  "type": "object"
                },
                "tags": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              },
              "required": [
                "selector"
              ]
            }
          ]
        }
      }
    }
  },
  "required": [
    "selectors",
    "checks"
  ]
}
"@
}

class SelectorReview {
    [hashtable] $Selectors = @{}
}

class SelectedResourceSet {
    [string] $Selector
    [string] $ResourceGraphQuery

    [SelectedResource[]] $Resources = @{}
}

class SelectedResource {
    [string] $ResourceId
    [string] $ResourceType
    [string] $ResourceName
    [string] $ResourceLocation
    [string] $ResourceGroupName

    [hashtable] $ResourceTags = @{}
}

class RunbookFactory {
    [Runbook] ParseRunbookFile([string] $path) {
        $fileContent = Get-Content -Path $path -Raw
        return $this.ParseRunbookContent($fileContent)
    }

    [Runbook] ParseRunbookContent([string] $runbookContent) {
        $runbookTable = ($runbookContent | ConvertFrom-Json -AsHashtable)

        $runbook = [Runbook]@{
            QueryPaths = ($runbookTable.query_paths ?? $runbookTable.query_overrides ?? @())
            Parameters = ($runbookTable.parameters ?? @{})
            Variables  = ($runbookTable.variables ?? @{})
            Selectors  = ($runbookTable.selectors ?? @{})
            Groupings  = ($runbookTable.groupings ?? @{})
        }

        foreach ($checkSetKey in $runbookTable.checks.Keys) {
            $checkSet = [RunbookCheckSet]::new()
            $checkSetTable = $runbookTable.checks[$checkSetKey]

            foreach ($checkKey in $checkSetTable.Keys) {
                $check = [RunbookCheck]::new()
                $checkValue = $checkSetTable[$checkKey]

                switch ($checkValue.GetType().Name.ToLower()) {
                    "string" {
                        $check.SelectorName = $checkValue
                    }
                    "orderedhashtable" {
                        $check.GroupingName = $checkValue.grouping
                        $check.SelectorName = $checkValue.selector
                        $check.Parameters = ($checkValue.parameters ?? @{})
                        $check.Tags = ($checkValue.tags ?? @())
                    }
                }

                $checkSet.Checks[$checkKey] = $check
            }

            $runbook.CheckSets[$checkSetKey] = $checkSet
        }

        return $runbook
    }
}

function Build-RunbookQueries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [Recommendation[]] $Recommendations
    )

    $queries = @()
    $globalParameters = @{}

    if ($Runbook.Parameters) {
        foreach ($globalParameterKey in $Runbook.Parameters.Keys) {
            $globalParameters[$globalParameterKey] = $Runbook.Parameters[$globalParameterKey].ToString()
        }
    }

    if ($Runbook.Variables) {
        foreach ($variableKey in $Runbook.Variables.Keys) {
            $variableValue = $Runbook.Variables[$variableKey].ToString()
            $globalParameters[$variableKey] = Merge-ParametersIntoString -Parameters $globalParameters -IntoString $variableValue
        }
    }

    $recommendationsHash = @{}
    $Recommendations.ForEach({ $recommendationsHash[$_.AprlGuid] = $_ })

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        if ($recommendationsHash.ContainsKey($checkSetKey)) {
            $checkSet = $Runbook.CheckSets[$checkSetKey]
            $recommendation = $recommendationsHash[$checkSetKey]

            foreach ($checkKey in $checkSet.Checks.Keys) {
                $check = $checkSet.Checks[$checkKey]

                $checkParameters = @{}
                $checkParameters += $globalParameters

                foreach ($checkParameterKey in $check.Parameters.Keys) {
                    $checkParameterValue = $check.Parameters[$checkParameterKey].ToString()
                    $checkParameters[$checkParameterKey] = Merge-ParametersIntoString -Parameters $checkParameters -Into $checkParameterValue
                }

                if ($Runbook.Selectors.ContainsKey($check.Selector)) {
                    $selector = Merge-ParametersIntoString -Parameters $checkParameters -Into $Runbook.Selectors[$check.Selector]
                    $query = Merge-ParametersIntoString -Parameters $checkParameters -Into $recommendation.Query
                    $query = $query -replace "//\s*selector", "| where $selector"

                    $queries += [RunbookCheckQuery]@{
                        CheckSetName   = $checkSetKey
                        CheckName      = $checkKey
                        Query          = $query
                        Recommendation = $recommendation
                    }
                }
                else {
                    throw "Runbook check [$checkSetKey]:[$checkKey] references a selector that does not exist: [$($check.Selector)]."
                }
            }
        }
        else {
            throw "Runbook check set [$checkSetKey] recommendation not found."
        }
    }

    return $queries
}

function Merge-ParametersIntoString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable] $Parameters,

        [Parameter(Mandatory = $true)]
        [string] $Into
    )

    foreach ($parameterKey in $Parameters.Keys) {
        $Into = $Into.Replace("{{$parameterKey}}", $Parameters[$parameterKey])
    }

    return $Into
}

function Read-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    Test-RunbookFile -Path $Path

    $runbookFactory = [RunbookFactory]::new()

    return $runbookFactory.ParseRunbookFile($Path)
}

function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    $errors = @()
    $fileContent = Get-Content -Path $Path -Raw

    if (-not ($fileContent | Test-Json)) {
        $errors = "- [$Path] is not a valid JSON file."
    }
    elseif (-not ($fileContent | Test-Json -Schema [Runbook]::Schema)) {
        $errors = "- [$Path] does not adhere to the runbook schema."
    }
    else {
        $runbookFactory = [RunbookFactory]::new()
        $runbook = $runbookFactory.ParseRunbookContent($fileContent)

        if ($runbook.Selectors.Count -eq 0) {
            $errors = "- No [selectors] defined. At least one (1) selector is required."
        }

        if ($runbook.CheckSets.Count -eq 0) {
            $errors = "- No [checks] defined. At least one (1) check set is required."
        }

        foreach ($queryPath in $runbook.QueryPaths) {
            if (-not (Test-Path -PathType Container -Path $queryPath)) {
                $errors += "- Query path [$queryPath] directory not found."
            }
        }

        foreach ($checkSetKey in $runbook.CheckSets.Keys) {
            $checkSet = $runbook.CheckSets[$checkSetKey]

            foreach ($checkKey in $checkSet.Checks.Keys) {
                $check = $checkSet.Checks[$checkKey]

                if (-not $runbook.Selectors.ContainsKey($check.SelectorName)) {
                    $errors += "- Check [$checkSetKey]:[$checkKey] references a selector that does not exist: [$($check.SelectorName)]."
                }

                if ($check.GroupingName -and -not $runbook.Groupings.ContainsKey($check.GroupingName)) {
                    $errors += "- Check [$checkSetKey]:[$checkKey] references a grouping that does not exist: [$($check.GroupingName)]."
                }
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw "Runbook file [$Path] is invalid:`n$($errors -join "`n")"
    }

    return $true
}

function Build-RunbookSelectorReview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection]
        [string[]] $SubscriptionIds
    )

    $selectorReview = [SelectorReview]::new()

    for ($i = 0; $i -lt $Runbook.Selectors.Keys.Count; $i++) {
        $selectorKey = $Runbook.Selectors.Keys[$i]
        $selector = $Runbook.Selectors[$selectorKey]
        $pctComplete = [int]((($i + 1) / $Runbook.Selectors.Keys.Count) * 100)

        Write-Progress `
            -Activity "Building selector review..." `
            -Status "$pctComplete% - Processing selector [$selectorKey]" `
            -PercentComplete $pctComplete

        $selectedResourceSet = [SelectedResourceSet]@{
            Selector           = $selector
            ResourceGraphQuery = Build-SelectorResourceGraphQuery -Selector $selector
        }

        $selectedResources = Invoke-WAFQuery `
            -Query $selectedResourceSet.SelectorResourceGraphQuery `
            -SubscriptionIds $SubscriptionIds

        foreach ($selectedResource in $selectedResources) {
            $selectedResourceSet.Resources += [SelectedResource]@{
                ResourceId        = $selectedResource.id
                ResourceType      = $selectedResource.type
                ResourceName      = $selectedResource.name
                ResourceLocation  = $selectedResource.location
                ResourceGroupName = $selectedResource.resourceGroup
                ResourceTags      = $selectedResource.tags
            }
        }

        $selectorReview.Selectors[$selectorKey] = $selectedResourceSet
    }

    Write-Progress -Activity "Selector review built." -Completed

    return $selectorReview
}

function Build-SelectorResourceGraphQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Selector
    )

    return @"
resources
| where $Selector
| project id, type, location, name, resourceGroup, tags
"@
}

