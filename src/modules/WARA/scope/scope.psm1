function Get-WAFResourceGroupsByList {
    param (
      [Parameter(Mandatory = $true)]
      [array]$ObjectList,

      [Parameter(Mandatory = $true)]
      [array]$FilterList,

      [Parameter(Mandatory = $true)]
      [string]$KeyColumn
    )

    $matchingObjects = foreach ($obj in $ObjectList) {
      if (($obj.$KeyColumn.split('/')[0..4] -join '/') -in $FilterList) {
        $obj
      }
    }

    return $matchingObjects
  }

  function Get-WAFSubscriptionsByList {
    param (
      [Parameter(Mandatory = $true)]
      [array]$ObjectList,

      [Parameter(Mandatory = $true)]
      [array]$FilterList,

      [Parameter(Mandatory = $true)]
      [string]$KeyColumn
    )

    $matchingObjects = foreach ($obj in $ObjectList) {
      if (($obj.$KeyColumn.split('/')[0..2] -join '/') -in $FilterList) {
        $obj
      }
    }

    return $matchingObjects
  }

  function Get-WAFResourcesByList {
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

function Get-WAFFilteredResourceList {
  param(
      [String[]]$SubscriptionFilters,
      [String[]]$ResourceGroupFilters,
      [String[]]$ResourceFilters
  )

  # TODO: ADD FILTERS FOR TAGS
  #Create a list of subscription ids based on the filters. Adds all the filters together then splits them into subscription Ids. Groups them to remove duplicates and returns a string array.
  $ImplicitSubscriptionIds = (($SubscriptionFilters + $ResourceGroupFilters + $ResourceFilters) | ForEach-Object {$_.split("/")[0..2] -join "/"} | Group | Select Name).Name

  $UnfilteredResources = Get-WAFAllAzGraphResource -subscriptionId ($ImplicitSubscriptionIds -replace ("/subscriptions/",""))

  $SubscriptionFilters ? ($SubscriptionFilteredResources = Get-WAFSubscriptionsByList -ObjectList $UnfilteredResources -FilterList $SubscriptionFilters -KeyColumn "Id") : "Subscription Filters not provided."

  $ResourceGroupFilters ? ($ResourceGroupFilteredResources = Get-WAFResourceGroupsByList -ObjectList $UnfilteredResources -FilterList $ResourceGroupFilters -KeyColumn "Id") : "Resource Group Filters not provided."

  $ResourceFilters ? ($ResourceFilteredResources = Get-WAFResourcesByList -ObjectList $UnfilteredResources -FilterList $ResourceFilters -KeyColumn "Id") : "Resource Filters not provided."

  #Originally used to remove duplicates but there was some weird interaction with the return object that caused it to duplicate the entire array. 
  #This just needs to be sorted outside of this function using | Sort-Object -Property Id -Unique
  $FilteredResources = $SubscriptionFilteredResources + $ResourceGroupFilteredResources + $ResourceFilteredResources

  return $FilteredResources

}
