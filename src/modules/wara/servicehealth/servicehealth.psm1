function Get-WAFServiceHealth {
    Param($Subid,$SubIds)

    $Servicequery = "resources | where type == 'microsoft.insights/activitylogalerts' | order by id"
    $queryResults = Invoke-WAFQuery -Query $Servicequery -subscriptionId $Subid

    $Rowler = foreach ($row in $queryResults) {
        foreach ($type in $row.properties.condition.allOf) {
            if ($type.equals -eq 'ServiceHealth') {
                $row
            }
        }
    }

    $AllServiceHealth = foreach ($Row in $Rowler) {
        $SubName = ($SubIds | Where-Object { $_.Id -eq ($Row.properties.scopes.split('/')[2]) }).Name
        $EventType = if ($Row.Properties.condition.allOf.anyOf | Select-Object -Property equals) { $Row.Properties.condition.allOf.anyOf | Select-Object -Property equals | ForEach-Object { switch ($_.equals) { 'Incident' { 'Service Issues' } 'Informational' { 'Health Advisories' } 'ActionRequired' { 'Security Advisory' } 'Maintenance' { 'Planned Maintenance' } } } } Else { 'All' }
        $Services = if ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ServiceName' }) { $Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ServiceName' } | Select-Object -Property containsAny | ForEach-Object { $_.containsAny } } Else { 'All' }
        $Regions = if ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ImpactedRegions[*].RegionName' }) { $Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ImpactedRegions[*].RegionName' } | Select-Object -Property containsAny | ForEach-Object { $_.containsAny } } Else { 'All' }
        $ActionGroupName = if ($Row.Properties.actions.actionGroups.actionGroupId) { $Row.Properties.actions.actionGroups.actionGroupId.split('/')[8] } else { '' }

            $result = [PSCustomObject]@{
                Name         = [string]$row.name
                Subscription = [string]$SubName
                Enabled      = [string]$Row.properties.enabled
                EventType    = $EventType
                Services     = $Services
                Regions      = $Regions
                ActionGroup  = $ActionGroupName
            }
            $result
        }
    return $AllServiceHealth
}