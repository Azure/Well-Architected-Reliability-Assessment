Function Get-WAFAllAzGraphResource {
    param (
      [string[]]$subscriptionId,
      [string]$query = 'Resources | project id, resourceGroup, subscriptionId, name, type, location'
    )

    if ($Debugging) {
      Write-Host
      Write-Host "[-Debugging]: Running resource graph query..." -ForegroundColor Magenta
      Write-Host
      Write-Host "$query" -ForegroundColor Magenta
      Write-Host
    }

    $result = $subscriptionId ? (Search-AzGraph -Query $query -first 1000 -Subscription $subscriptionId) : (Search-AzGraph -Query $query -first 1000 -usetenantscope) # -first 1000 returns the first 1000 results and subsequently reduces the amount of queries required to get data.

    # Collection to store all resources
    $allResources = @($result)

    # Loop to paginate through the results using the skip token
    while ($result.SkipToken) {
      # Retrieve the next set of results using the skip token
      $result = $subscriptionId ? (Search-AzGraph -Query $query -SkipToken $result.SkipToken -Subscription $subscriptionId -First 1000) : (Search-AzGraph -query $query -SkipToken $result.SkipToken -First 1000 -UseTenantScope)
      # Add the results to the collection
      $allResources += $result
    }

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

    $r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionId $SubscriptionIds -usetenantscope) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)

    # Returns the resource groups
    return $r
  }

#This function grabs all resources inside of resource groups with matching tags.

#This function grabs all resources that have matching tags and returns them.
Function Get-TaggedResources {
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

$r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionId $SubscriptionIds) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)
return $r
}
#This function grabs all resources that have matching tags and returns them.
Function Get-TaggedRGResources {
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

$r = $SubscriptionIds ? (Get-WAFAllAzGraphResource -query $q -subscriptionId $SubscriptionIds) : (Get-WAFAllAzGraphResource -query $q -usetenantscope)
return $r
}
