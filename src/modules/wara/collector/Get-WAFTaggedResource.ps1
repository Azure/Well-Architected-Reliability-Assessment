<#
.SYNOPSIS
    Retrieves all resources with matching tags.

.DESCRIPTION
    The Get-WAFTaggedResources function queries Azure Resource Graph to retrieve all resources that have matching tags.

.PARAMETER tagArray
    An array of tags to filter resources by. Each tag should be in the format 'key==value'.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of resources with matching tags.

.EXAMPLE
    $taggedResources = Get-WAFTaggedResources -tagArray @('env==prod', 'app==myapp') -SubscriptionIds @('sub1', 'sub2')

.NOTES
    This function uses the Invoke-WAFQuery function to perform the query.
#>
function Get-WAFTaggedResource {
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

        $tagquery = "resources
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
