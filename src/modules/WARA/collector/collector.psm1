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

#This function grabs all resources inside of resource groups with matching tags.

#This function grabs all resources that have matching tags and returns them.
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
#This function grabs all resources that have matching tags and returns them.
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

Function Invoke-WAFQueryLoop {
  param(
    $RecommendationObject,
    [string[]]$subscriptionIds
  )

  $Types = Get-WAFResourceType -SubscriptionIds $subscriptionIds

  $QueryObject = Get-WAFQueryByResourceType -ObjectList $RecommendationObject -FilterList $Types.type -KeyColumn "recommendationResourceType"

  $return = $QueryObject | Where{$_.automationavailable -eq "arg"} | ForEach-Object {
    Get-WAFAllAzGraphResource -query $_.query -subscriptionIds $subscriptionIds
  }

  return $return
}

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
