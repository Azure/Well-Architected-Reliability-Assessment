<#
.SYNOPSIS
    Builds service health alert objects from query results.

.DESCRIPTION
    The `Build-WAFServiceHealthObject` function processes the results obtained from the Azure Resource Graph query and constructs custom objects representing service health alerts with relevant details.

.PARAMETER AdvQueryResult
    The results from the Azure Resource Graph query.

.INPUTS
    System.Object[]. Accepts an array of query result objects.

.OUTPUTS
    System.Object[]. Returns an array of service health alert objects with detailed properties.

.EXAMPLE
    # Process query results to get service health alert objects
    $queryResults = Invoke-WAFQuery -Query $Servicequery -SubscriptionIds $SubscriptionIds
    $serviceHealthAlerts = Build-WAFServiceHealthObject -AdvQueryResult $queryResults

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Build-WAFServiceHealthObject {
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $AdvQueryResult
    )

    $return = $AdvQueryResult.ForEach({ [ServiceHealthAlert]::new($_) })

    return $return
}
