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
Function Get-WAFTaggedResource {
  [CmdletBinding()]
param(
  [array]$tagArray,
  [string[]]$subscriptionIds
)

$return = @()

foreach($tag in $tagArray){
  switch -Wildcard ($tag)
  {
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

  $result = Invoke-WAFQuery -query $tagquery -subscriptionIds $subscriptionIds
  
  $return += $result
}

$return = ($return | Group-Object id | Where-Object {$_.count -eq $tagArray.Count} | Select-Object Name).Name

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
Function Get-WAFTaggedRGResource {
  [CmdletBinding()]
  param(
    [array]$tagArray,
    [string[]]$subscriptionIds
)

$return = @()

foreach($tag in $tagArray){

    switch -Wildcard ($tag)
    {
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

    $result = Invoke-WAFQuery -query $tagquery -subscriptionIds $subscriptionIds
    
    $return += $result
}

$return = ($return | Group-Object id | Where-Object {$_.count -eq $tagArray.Count} | Select-Object Name).Name

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
Function Invoke-WAFQueryLoop {
  [CmdletBinding()]
param(
  $RecommendationObject,
  [string[]]$subscriptionIds
)

$Types = Get-WAFResourceType -SubscriptionIds $subscriptionIds

$QueryObject = Get-WAFQueryByResourceType -ObjectList $RecommendationObject -FilterList $Types.type -KeyColumn "recommendationResourceType"

$return = $QueryObject.Where({$_.automationavailable -eq $True -and [String]::IsNullOrEmpty($_.recommendationTypeId)}) | ForEach-Object {
  Write-Progress -Activity "Running Queries" -Status "Running Query for $($_.recommendationResourceType) - $($_.aprlGuid)" -PercentComplete (($QueryObject.IndexOf($_) / $QueryObject.Count) * 100)
  try{
    Invoke-WAFQuery -query $_.query -subscriptionIds $subscriptionIds -ErrorAction Stop
  }
  catch{
    Write-Host "Error running query for - " $_.aprlGuid
  }
}

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
Function Get-WAFResourceType {
  [CmdletBinding()]
param(
  [String[]]$SubscriptionIds
)

$q = "Resources
| summarize count() by type
| project type"

$r = $SubscriptionIds ? (Invoke-WAFQuery -query $q -subscriptionIds $SubscriptionIds) : (Invoke-WAFQuery -query $q -usetenantscope)

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
  [array]$ObjectList,

  [Parameter(Mandatory = $true)]
  [array]$FilterList,

  [Parameter(Mandatory = $true)]
  [string]$KeyColumn
)

$matchingObjects = foreach ($obj in $ObjectList) {
  if ($obj.$KeyColumn -in $FilterList) {
    $obj
  }
}

return $matchingObjects
}