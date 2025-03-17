<#
.FUNCTION
    Build-RunbookQueries

.SYNOPSIS
    Constructs queries for runbook checks.

.DESCRIPTION
    The `Build-RunbookQueries` function generates a list of queries based on the check sets
    and associated recommendations within a runbook. It dynamically merges parameters, variables,
    and selectors to construct accurate queries for evaluation.

.PARAMETER Runbook
    The `Runbook` object containing check sets, parameters, and selectors.

.PARAMETER Recommendations
    An array of `RunbookRecommendation` objects defining the checks to be executed.

.PARAMETER ProgressId
    (Optional) A progress indicator ID for `Write-Progress`.

.OUTPUTS
    [RunbookQuery[]]
    An array of `RunbookQuery` objects, each containing a check name, query, tags, and recommendation.

.EXAMPLE
    $queries = Build-RunbookQueries -Runbook $runbook -Recommendations $recommendations

    Constructs queries for the given runbook and recommendations.

.NOTES
    - Queries are created by combining parameters, variables, and selectors with recommendation queries.
    - Throws an error if a check references a missing selector.
    - Ensures that only recommendations matching the runbook's check sets are processed.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Build-RunbookQueries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [RunbookRecommendation[]] $Recommendations,

        [Parameter(Mandatory = $false)]
        [int] $ProgressId = 30
    )

    $checkCount = 0
    $checkIndex = 0

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        $checkSet = $Runbook.CheckSets[$checkSetKey]
        $checkCount += $checkSet.Checks.Count
    }

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
            $globalParameters[$variableKey] = Merge-ParametersIntoString -Parameters $globalParameters -Into $variableValue
        }
    }

    $recommendationsMap = @{}

    foreach ($recommendation in $Recommendations) {
        if (-not ($recommendationsMap.ContainsKey($recommendation.CheckSetName))) {
            $recommendationsMap[$recommendation.CheckSetName] = @{}
        }

        $recommendationsMap[$recommendation.CheckSetName][$recommendation.CheckName] = $recommendation.Recommendation
    }

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        if (-not ($recommendationsMap.ContainsKey($checkSetKey))) {
            throw "No recommendations found for check set [$checkSetKey]."
        }

        $checkSet = $Runbook.CheckSets[$checkSetKey]

        foreach ($checkKey in $checkSet.Checks.Keys) {
            $checkIndex++
            $pctComplete = (($checkIndex / $checkCount) * 100)

            Write-Progress `
                -Activity "Building runbook queries" `
                -Status "$checkKey" `
                -PercentComplete $pctComplete `
                -Id $ProgressId

            if (-not ($recommendationsMap[$checkSetKey].ContainsKey($checkKey))) {
                throw "No recommendation found for check [$checkSetKey]:[$checkKey]."
            }

            $check = $checkSet.Checks[$checkKey]
            $recommendation = $recommendationsMap[$checkSetKey][$checkKey]

            $checkParameters = @{}
            $checkParameters += $globalParameters

            foreach ($checkParameterKey in $check.Parameters.Keys) {
                $checkParameterValue = $check.Parameters[$checkParameterKey].ToString()
                $checkParameters[$checkParameterKey] = Merge-ParametersIntoString -Parameters $globalParameters -Into $checkParameterValue
            }

            if ($Runbook.Selectors.ContainsKey($check.SelectorName)) {
                $query = Merge-ParametersIntoString -Parameters $checkParameters -Into $recommendation.Query

                foreach ($selectorKey in $Runbook.Selectors.Keys) {
                    $selector = $Runbook.Selectors[$selectorKey]
                    $selector = Merge-ParametersIntoString -Parameters $checkParameters -Into $selector
                    $query = $($query -replace "//\s*selector:$($selectorKey)", "| where $selector")
                }

                $selector = Merge-ParametersIntoString -Parameters $checkParameters -Into $Runbook.Selectors[$check.SelectorName]
                $query = $($query -replace "//\s*selector", "| where $selector")

                $queries += [RunbookQuery]@{
                    CheckSetName   = $checkSetKey
                    CheckName      = $checkKey
                    SelectorName   = $check.SelectorName
                    Query          = $query
                    Tags           = $check.Tags
                    Recommendation = $recommendation
                }
            }
        }
    }

    Write-Progress -Id $ProgressId -Completed

    return $queries
}
