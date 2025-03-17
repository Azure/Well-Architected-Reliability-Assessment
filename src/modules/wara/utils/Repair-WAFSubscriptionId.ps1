<#
    .SYNOPSIS
        Ensures that subscription IDs are in the correct ARM resource ID format by adding "/subscriptions/" prefix if missing.

    .DESCRIPTION
        The `Repair-WAFSubscriptionId` function accepts an array of subscription IDs and checks each one to ensure it follows the Azure Resource Manager (ARM) resource ID format. If a subscription ID does not start with "/subscriptions/", the function prefixes it with "/subscriptions/". This standardizes the subscription IDs for consistent use in ARM queries and operations.

    .PARAMETER SubscriptionIds
        An array of subscription ID strings to validate and correct if necessary.

    .INPUTS
        System.String[]. You can pipe an array of subscription ID strings to this function.

    .OUTPUTS
        System.String[]. Returns an array of subscription IDs, each starting with "/subscriptions/".

    .EXAMPLE
        PS> $subs = @("59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57", "/subscriptions/abcd1234-5678-90ab-cdef-1234567890ab")
        PS> $fixedSubs = Repair-WAFSubscriptionId -SubscriptionIds $subs
        PS> $fixedSubs

        Output:
        /subscriptions/59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57
        /subscriptions/abcd1234-5678-90ab-cdef-1234567890ab

        This example demonstrates that the function adds the "/subscriptions/" prefix to a subscription ID that lacks it and leaves properly formatted IDs unchanged.

    .EXAMPLE
        PS> $subs = @()
        PS> $fixedSubs = Repair-WAFSubscriptionId -SubscriptionIds $subs

        This example shows that the function correctly handles an empty array without errors, returning an empty array.

    .EXAMPLE
        PS> $subs = @("invalid-guid", "12345678-1234-1234-1234-1234567890ab")
        PS> $fixedSubs = Repair-WAFSubscriptionId -SubscriptionIds $subs
        PS> $fixedSubs

        Output:
        /subscriptions/invalid-guid
        /subscriptions/12345678-1234-1234-1234-1234567890ab

        This example illustrates that the function does not validate the format of the GUID itself; it only ensures the prefix is present.

    .NOTES
        Author: Kyle Poineal
        Date: 2024-12-12
    #>
function Repair-WAFSubscriptionId {
    [CmdletBinding()]
    [Parameter(Mandatory = $true)]
    [AllowEmptyCollection()]
    param (
        [string[]] $SubscriptionIds
    )

    $fixedSubscriptionIds = @()
    foreach ($subscriptionId in $SubscriptionIds) {
        if ($subscriptionId -notmatch '\/subscriptions\/') {
            $fixedSubscriptionIds += "/subscriptions/$subscriptionId"
        }
        else {
            $fixedSubscriptionIds += $subscriptionId
        }
    }
    return $fixedSubscriptionIds
}