<#
.SYNOPSIS
    Retrieves all resources in resource groups with matching tags.

.DESCRIPTION
    The Get-WAFTaggedRGResources function queries Azure Resource Graph to retrieve all resources in resource groups that have matching tags.

.PARAMETER tagKeys
    An array of tag keys to filter resource groups by.

.PARAMETER tagValues
    An array of tag values to filter resource groups by.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of resources in resource groups with matching tags.

.EXAMPLE
    $taggedRGResources = Get-WAFTaggedRGResources -tagKeys @('env') -tagValues @('prod') -SubscriptionIds @('sub1', 'sub2')

.NOTES
    This function uses the Invoke-WAFQuery function to perform the query.
#>
function Get-WAFTaggedResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $TagArray,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $return = @()

    foreach ($tag in $TagArray) {
        switch -Wildcard ($tag) {
            "*=~*" {
                $tagKeys = $tag.Split("=~")[0].split("||") -join ("','")
                $tagValues = $tag.Split("=~")[1].split("||") -join ("','")
                $in = "in~"
            }
            "*!~*" {
                $tagKeys = $tag.Split("!~")[0].split("||") -join ("','")
                $tagValues = $tag.Split("!~")[1].split("||") -join ("','")
                $in = "!in~"
            }
        }

        $tagquery = `
            "resourcecontainers
| where type == 'microsoft.resources/subscriptions/resourcegroups'
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tolower(tags[0]) in~ ('$tagKeys')  // Specify your tag names here
| where tolower(tags[1]) $in ('$tagValues')  // Specify your tag values here
| summarize by id
| order by ['id']"

        $result = Invoke-WAFQuery -Query $tagquery -SubscriptionIds $SubscriptionIds

        $return += $result
    }

    $return = ($return | Group-Object id | Where-Object { $_.count -eq $TagArray.Count } | Select-Object Name).Name

    return $return
}
