using module ../utils/utils.psd1

function Get-WAFServiceHealth {
    [CmdletBinding()]
    Param(
        [String[]]$SubscriptionIds
        )

    $Servicequery = `
"resources
| where type == 'microsoft.insights/activitylogalerts' and properties.condition has 'ServiceHealth'
| join kind=inner (
    resourcecontainers
    | where type == 'microsoft.resources/subscriptions'
    | project subscriptionId, subscriptionName = name
) on subscriptionId
| project subscriptionId, subscriptionName, eventName = name, type, location, resourceGroup, properties"

    $queryResults = Invoke-WAFQuery -Query $Servicequery -subscriptionIds $SubscriptionIds

    $AllServiceHealth = Build-WAFServiceHealthObject -AdvQueryResult $queryResults
    
    return $AllServiceHealth
}

function Build-WAFServiceHealthObject {
    Param($AdvQueryResult)

    $return = $AdvQueryResult.ForEach({ [ServiceHealthAlert]::new($_) })

    return $return
}

class ServiceHealthAlert {
    [string]$Name
    [string]$Subscription
    [string]$Enabled
    [string]$EventType
    [string]$Services
    [string]$Regions
    [string]$ActionGroup

    ServiceHealthAlert([PSCustomObject]$row) {
        $this.Name = $Row.eventName
        $this.Subscription = $Row.subscriptionName
        $this.Enabled = $Row.properties.enabled
        $this.EventType = [ServiceHealthAlert]::GetEventType($Row)
        $this.Services = [ServiceHealthAlert]::GetServices($Row)
        $this.Regions = [ServiceHealthAlert]::GetRegions($Row)
        $this.ActionGroup = [ServiceHealthAlert]::GetActionGroupName($Row)
    }

    static [string] GetEventType($Row) {
        if ($Row.Properties.condition.allOf.anyOf | Select-Object -Property equals) {
            return ($Row.Properties.condition.allOf.anyOf | Select-Object -Property equals | ForEach-Object {
                switch ($_.equals) {
                    'Incident' { 'Service Issues' }
                    'Informational' { 'Health Advisories' }
                    'ActionRequired' { 'Security Advisory' }
                    'Maintenance' { 'Planned Maintenance' }
                    default { 'All' }
                }
            }) -join ', '
        } else {
            return 'All'
        }
    }

    static [string] GetServices($Row) {
        if ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ServiceName' }) {
            return ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ServiceName' } | Select-Object -Property containsAny | ForEach-Object { $_.containsAny }) -join ', '
        } else {
            return 'All'
        }
    }

    static [string] GetRegions($Row) {
        if ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ImpactedRegions[*].RegionName' }) {
            return ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ImpactedRegions[*].RegionName' } | Select-Object -Property containsAny | ForEach-Object { $_.containsAny }) -join ', '
        } else {
            return 'All'
        }
    }

    static [string] GetActionGroupName($Row) {
        if ($Row.Properties.actions.actionGroups.actionGroupId) {
            return $Row.Properties.actions.actionGroups.actionGroupId.split('/')[8]
        } else {
            return ''
        }
    }
}