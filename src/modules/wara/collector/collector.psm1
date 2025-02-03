using module ../utils/utils.psd1

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
| where tolower(tags[0]) in~ ('$tagkeys')  // Specify your tag names here
| where tolower(tags[1]) $in ('$tagvalues')  // Specify your tag values here
| summarize by id
| order by ['id']"

        $result = Invoke-WAFQuery -Query $tagquery -SubscriptionIds $SubscriptionIds

        $return += $result
    }

    $return = ($return | Group-Object id | Where-Object { $_.count -eq $TagArray.Count } | Select-Object Name).Name

    return $return
}

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

<#
.SYNOPSIS
    Invokes a loop to run queries for each recommendation object.

.DESCRIPTION
    The Invoke-WAFQueryLoop function runs queries for each recommendation object and retrieves the resources.

.PARAMETER RecommendationObject
    An array of recommendation objects to query.

.PARAMETER subscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of resources for each recommendation object.

.EXAMPLE
    $resources = Invoke-WAFQueryLoop -RecommendationObject $recommendations -subscriptionIds @('sub1', 'sub2')

.NOTES
    This function uses the Invoke-WAFQuery function to perform the queries.
#>
function Invoke-WAFQueryLoop {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $RecommendationObject,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]] $AddedTypes,

        [Parameter(Mandatory = $false)]
        [int] $ProgressId = 1
    )

    $Types = Get-WAFResourceType -SubscriptionIds $SubscriptionIds

    $QueryObject = Get-WAFQueryByResourceType -ObjectList $RecommendationObject -FilterList $Types.type -KeyColumn 'recommendationResourceType'

    # Add additional types to query based on specialized workloads (This works even if it's empty.)
    $QueryObject += $AddedTypes.Foreach({
        $type = $_
        $RecommendationObject.where({$_.tags -contains $type})
    }) | Sort-Object -Property "APRLGuid" | Get-Unique -AsString

    $return = $QueryObject.Where({ $_.automationAvailable -eq $true -and $_.recommendationMetadataState -eq "Active" -and [string]::IsNullOrEmpty($_.recommendationTypeId) }) | ForEach-Object {
        Write-Progress -Activity 'Running Queries' -Status "Running Query for $($_.recommendationResourceType) - $($_.aprlGuid)" -PercentComplete (($QueryObject.IndexOf($_) / $QueryObject.Count) * 100) -Id $ProgressId
        try {
            (Invoke-WAFQuery -Query $_.query -SubscriptionIds $subscriptionIds -ErrorAction Stop)
        }
        catch {
            $errorInfo = "Error running query for - $($_.recommendationResourceType) - $($_.aprlGuid)"
            Write-Error $errorInfo
            return $errorInfo
        }
    }
    Write-Progress -Activity 'Running Queries' -Status 'Completed' -Completed -Id $ProgressId

    return $return
}

<#
.SYNOPSIS
    Retrieves all resource types in the specified subscriptions.

.DESCRIPTION
    The Get-WAFResourceType function queries Azure Resource Graph to retrieve all resource types in the specified subscriptions.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the query.

.OUTPUTS
    Returns an array of resource types.

.EXAMPLE
    $resourceTypes = Get-WAFResourceType -SubscriptionIds @('sub1', 'sub2')

.NOTES
    This function uses the Invoke-WAFQuery function to perform the query.
#>
function Get-WAFResourceType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $q = "Resources
| summarize count() by type
| project type"

    $r = $SubscriptionIds ? (Invoke-WAFQuery -Query $q -SubscriptionIds $SubscriptionIds) : (Invoke-WAFQuery -Query $q)

    return $r
}

<#
.SYNOPSIS
    Filters objects by resource type.

.DESCRIPTION
    The Get-WAFQueryByResourceType function filters a list of objects by resource type.

.PARAMETER ObjectList
    An array of objects to filter.

.PARAMETER FilterList
    An array of resource types to filter by.

.PARAMETER KeyColumn
    The key column to use for filtering.

.OUTPUTS
    Returns an array of objects that match the specified resource types.

.EXAMPLE
    $filteredObjects = Get-WAFQueryByResourceType -ObjectList $objects -FilterList $types -KeyColumn "type"
#>
function Get-WAFQueryByResourceType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]] $ObjectList,

        [Parameter(Mandatory = $true)]
        [string[]] $FilterList,

        [Parameter(Mandatory = $true)]
        [string] $KeyColumn
    )

    $matchingObjects = foreach ($obj in $ObjectList) {
        if ($obj.$KeyColumn -in $FilterList) {
            $obj
        }
    }

    return $matchingObjects
}
