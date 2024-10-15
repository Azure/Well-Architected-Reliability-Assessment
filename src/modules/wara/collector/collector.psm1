<#
.SYNOPSIS
Retrieves all Azure resources using Azure Resource Graph.
.DESCRIPTION
The Get-WAFAllAzGraphResource function queries Azure Resource Graph to retrieve all resources based on the provided query and subscription IDs.
.PARAMETER subscriptionIds
An array of subscription IDs to scope the query.
.PARAMETER query
The query to run against Azure Resource Graph. Defaults to a query that retrieves basic resource information.
.OUTPUTS
Returns an array of resources.
.EXAMPLE
$resources = Get-WAFAllAzGraphResource -subscriptionIds @('sub1', 'sub2')
.NOTES
This function handles pagination using the SkipToken.
#>
Function Get-WAFAllAzGraphResource {
  param (
    [string[]]$subscriptionIds,
    [string]$query = 'Resources | project id, resourceGroup, subscriptionId, name, type, location'
  )

  if ($Debugging) {
    Write-Host
    Write-Host "[-Debugging]: Running resource graph query..." -ForegroundColor Magenta
    Write-Host
    Write-Host "$query" -ForegroundColor Magenta
    Write-Host
  }

  $result = $subscriptionIds ? (Search-AzGraph -Query $query -first 1000 -Subscription $subscriptionIds) : (Search-AzGraph -Query $query -first 1000 -usetenantscope) # -first 1000 returns the first 1000 results and subsequently reduces the amount of queries required to get data.

  # Collection to store all resources
  $allResources = @($result)

  # Loop to paginate through the results using the skip token
  $result = while ($result.SkipToken) {
    # Retrieve the next set of results using the skip token
    $result = $subscriptionId ? (Search-AzGraph -Query $query -SkipToken $result.SkipToken -Subscription $subscriptionIds -First 1000) : (Search-AzGraph -query $query -SkipToken $result.SkipToken -First 1000 -UseTenantScope)
    # Add the results to the collection
    write-output $result
  }

  $allResources += $result

  # Output all resources
  return $allResources
}

<#
.SYNOPSIS
Retrieves all resource groups in the specified subscriptions.
.DESCRIPTION
The Get-WAFResourceGroup function queries Azure Resource Graph to retrieve all resource groups in the specified subscriptions.
.PARAMETER SubscriptionIds
An array of subscription IDs to scope the query.
.OUTPUTS
Returns an array of resource groups.
.EXAMPLE
$resourceGroups = Get-WAFResourceGroup -SubscriptionIds @('sub1', 'sub2')
.NOTES
This function uses the Get-WAFAllAzGraphResource function to perform the query.
#>
function Get-WAFResourceGroup {
  param (
    [string[]]$SubscriptionIds
  )

  # Query to get all resource groups in the tenant
  $q = "resourcecontainers
  | where type == 'microsoft.resources/subscriptions'
  | project subscriptionId, subscriptionName = name
  | join (resourcecontainers
      | where type == 'microsoft.resources/subscriptions/resourcegroups')
      on subscriptionId
  | project subscriptionName, subscriptionId, resourceGroup, id=tolower(id)"

  $r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionIds $SubscriptionIds -usetenantscope) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)

  # Returns the resource groups
  return $r
}

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
This function uses the Get-WAFAllAzGraphResource function to perform the query.
#>
Function Get-WAFTaggedResources {
param(
    [String[]]$tagArray,
    [String[]]$SubscriptionIds
)

$queryTemplate = "| where (tags['<name>'] =~ '<value>')"

$queryobj = @()
foreach($tag in $tagArray){
    $tagName, $tagValue = $tag.Split('==').Trim()
    $queryobj += $queryTemplate -replace "<name>", $tagName -replace "<value>", $tagValue
}

$queryobj = $queryobj -join "`r`n"

$q = "resources
<insert>
| project id, name, type, location, resourceGroup, subscriptionId" -replace "<insert>", $queryobj

Write-host The Query is: `r`n $q

$r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionIds $SubscriptionIds) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)
return $r
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
This function uses the Get-WAFAllAzGraphResource function to perform the query.
#>
Function Get-WAFTaggedRGResources {
param(
    [String[]]$tagKeys,
    [String[]]$tagValues,
    [String[]]$SubscriptionIds
)

$tagValuesString = "'" + ($tagValues -join "','").toLower() + "'"
$tagKeysString = "'" + ($tagKeys -join "','").toLower() + "'"

$q = "Resources
| mv-expand bagexpansion=array tags
| where isnotempty(tags)
| where tolower(tags[0]) in ($tagValuesString)  // Specify your tag names here
| where tolower(tags[1]) in ($tagKeysString)  // Specify your tag values here
| project name,id,type,resourceGroup,location,subscriptionId"

Write-host The Query is $q

$r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionIds $SubscriptionIds) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)
return $r
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
This function uses the Get-WAFAllAzGraphResource function to perform the queries.
#>
Function Invoke-WAFQueryLoop {
param(
  $RecommendationObject,
  [string[]]$subscriptionIds
)

$Types = Get-WAFResourceType -SubscriptionIds $subscriptionIds

$QueryObject = Get-WAFQueryByResourceType -ObjectList $RecommendationObject -FilterList $Types.type -KeyColumn "recommendationResourceType"

$return = $QueryObject | Where-Object{$_.automationavailable -eq "arg"} | ForEach-Object {
  Write-Progress -Activity "Running Queries" -Status "Running Query for $($_.recommendationResourceType) - $($_.aprlGuid)" -PercentComplete (($QueryObject.IndexOf($_) / $QueryObject.Count) * 100)
  Get-WAFAllAzGraphResource -query $_.query -subscriptionIds $subscriptionIds
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
This function uses the Get-WAFAllAzGraphResource function to perform the query.
#>
Function Get-WAFResourceType {
param(
  [String[]]$SubscriptionIds
)

$q = "Resources
| summarize count() by type
| project type"

$r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionIds $SubscriptionIds) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)

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