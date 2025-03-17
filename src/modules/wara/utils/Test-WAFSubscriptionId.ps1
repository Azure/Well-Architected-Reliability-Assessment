<#
.SYNOPSIS
    Validates an array of subscription IDs.

.DESCRIPTION
    The `Test-WAFSubscriptionId` function checks if each subscription ID in the input array is a valid GUID format. It throws an error if any subscription ID is invalid.

.PARAMETER InputValue
    An array of subscription IDs to validate.

.INPUTS
    System.String[]. The function accepts an array of subscription ID strings.

.OUTPUTS
    None. Throws an error if validation fails.

.EXAMPLE
    PS> Test-WAFSubscriptionId -InputValue @("59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57", "invalid-guid")

    Error:
    The subscription ID 'invalid-guid' is not a valid GUID.

    This example demonstrates validation failure when an invalid subscription ID is provided.

.EXAMPLE
    PS> Test-WAFSubscriptionId -InputValue @("59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57")

    This example validates a valid subscription ID without any error.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Test-WAFSubscriptionId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $InputValue
            )

    $pattern = '^(\/subscriptions\/)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\/?$'

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
