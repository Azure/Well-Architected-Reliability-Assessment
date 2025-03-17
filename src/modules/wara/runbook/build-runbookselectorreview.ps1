<#
.FUNCTION
    Build-RunbookSelectorReview

.SYNOPSIS
    Builds a selector review for a runbook.

.DESCRIPTION
    The `Build-RunbookSelectorReview` function evaluates each selector in a runbook,
    resolves parameters, and executes queries to identify matching resources across
    specified subscriptions.

.PARAMETER Runbook
    The `Runbook` object containing selectors, parameters, and variables.

.PARAMETER SubscriptionIds
    (Optional) An array of subscription IDs to scope the queries.

.OUTPUTS
    [SelectorReview]
    A `SelectorReview` object mapping each selector to its resolved query and matched resources.

.EXAMPLE
    $review = Build-RunbookSelectorReview -Runbook $runbook -SubscriptionIds @("sub1", "sub2")

    Generates a selector review to verify correct resource scoping.

.NOTES
    - Selectors define which resources are included in a runbook.
    - Misconfigured selectors may cause missing or incorrect results.
    - Uses `Invoke-WAFQuery` to fetch matching resources.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Build-RunbookSelectorReview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $selectorReview = [SelectorReview]::new()

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

    for ($i = 0; $i -lt $Runbook.Selectors.Keys.Count; $i++) {
        $selectorKey = $Runbook.Selectors.Keys[$i]
        $selector = Merge-ParametersIntoString -Parameters $globalParameters -Into $Runbook.Selectors[$selectorKey]
        $pctComplete = ((($i + 1) / $Runbook.Selectors.Keys.Count) * 100)

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
                ResourceTags      = $(ConvertTo-Json $selectedResource.tags | ConvertFrom-Json -AsHashtable)
            }
        }

        $selectorReview.Selectors[$selectorKey] = $selectedResourceSet
    }

    Write-Progress -Activity "Selector review built." -Completed

    return $selectorReview
}
