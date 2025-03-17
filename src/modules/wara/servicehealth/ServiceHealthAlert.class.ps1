<#
.SYNOPSIS
    Represents a Service Health Alert retrieved from Azure.

.DESCRIPTION
    The `ServiceHealthAlert` class encapsulates the details of a service health alert from Azure. It provides properties to access alert information such as the name, subscription, status, event type, affected services, regions, and associated action groups. The class includes methods to parse and extract specific details from the alert data.

.PROPERTIES
    [string] Name
        The name of the service health alert.

    [string] Subscription
        The name of the Azure subscription where the alert is configured.

    [string] Enabled
        Indicates whether the alert is enabled or disabled.

    [string] EventType
        The type of event the alert is configured to monitor (e.g., 'Service Health Incident', 'Planned Maintenance').

    [string] Services
        A comma-separated list of Azure services that the alert monitors.

    [string] Regions
        A comma-separated list of Azure regions that the alert monitors.

    [string] ActionGroup
        The name of the action group associated with the alert for notifications.

.CONSTRUCTORS
    ServiceHealthAlert([PSCustomObject] $Row)
        Initializes a new instance of the `ServiceHealthAlert` class using the provided alert data.

.METHODS
    static [string] GetEventType([PSCustomObject] $Row)
        Parses and returns the event type from the alert data.

    static [string] GetServices([PSCustomObject] $Row)
        Extracts and returns the services monitored by the alert.

    static [string] GetRegions([PSCustomObject] $Row)
        Extracts and returns the regions monitored by the alert.

    static [string] GetActionGroupName([PSCustomObject] $Row)
        Retrieves and returns the name of the action group associated with the alert.

.EXAMPLE
    # Example of creating ServiceHealthAlert objects from query results
    $queryResults = Invoke-WAFQuery -Query $ServiceQuery -SubscriptionIds $SubscriptionIds
    $serviceHealthAlerts = $queryResults.ForEach({ [ServiceHealthAlert]::new($_) })

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
class ServiceHealthAlert {
    [string] $Name
    [string] $Subscription
    [string] $Enabled
    [string] $EventType
    [string] $Services
    [string] $Regions
    [string] $ActionGroup

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
        $equals = ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.incidentType' } | Select-Object -Property equals).equals
        $return = switch ($equals) {
            'Incident' { 'Service Issues' }
            'Informational' { 'Health Advisories' }
            'ActionRequired' { 'Security Advisory' }
            'Maintenance' { 'Planned Maintenance' }
            default { 'All' }
        }

        return $return
    }

    static [string] GetServices($Row) {
        if ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ServiceName' }) {
            return ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ServiceName' } | Select-Object -Property containsAny | ForEach-Object { $_.containsAny }) -join ', '
        }
        else {
            return 'All'
        }
    }

    static [string] GetRegions($Row) {
        if ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ImpactedRegions[*].RegionName' }) {
            return ($Row.Properties.condition.allOf | Where-Object { $_.field -eq 'properties.impactedServices[*].ImpactedRegions[*].RegionName' } | Select-Object -Property containsAny | ForEach-Object { $_.containsAny }) -join ', '
        }
        else {
            return 'All'
        }
    }

    static [string] GetActionGroupName($Row) {
        if ($Row.Properties.actions.actionGroups.actionGroupId) {
            return $Row.Properties.actions.actionGroups.actionGroupId.split('/')[8]
        }
        else {
            return ''
        }
    }
}
