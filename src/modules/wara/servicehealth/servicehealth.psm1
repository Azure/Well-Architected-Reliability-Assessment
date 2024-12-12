using module ../utils/utils.psd1
<#
.SYNOPSIS
    Retrieves service health alerts from specified Azure subscriptions.

.DESCRIPTION
    The `Get-WAFServiceHealth` function queries Azure Resource Graph to retrieve service health alerts from the provided subscription IDs. It searches for activity log alerts related to 'ServiceHealth' and joins them with subscription information.

.PARAMETER SubscriptionIds
    An array of Azure subscription IDs for which to retrieve service health alerts.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.Object[]. Returns an array of service health alert objects.

.EXAMPLE
    # Retrieve service health alerts for multiple subscriptions
    $subscriptions = @('59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57', 'abcd1234-5678-90ab-cdef-1234567890ab')
    $serviceHealthAlerts = Get-WAFServiceHealth -SubscriptionIds $subscriptions

.EXAMPLE
    # Retrieve service health alerts for a single subscription
    $serviceHealthAlerts = Get-WAFServiceHealth -SubscriptionIds '59f6f1ab-6d68-4c90-b4e5-ad2d71cefc57'

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Get-WAFServiceHealth {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
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

    $queryResults = Invoke-WAFQuery -Query $Servicequery -SubscriptionIds $SubscriptionIds

    $AllServiceHealth = Build-WAFServiceHealthObject -AdvQueryResult $queryResults
    
    return $AllServiceHealth
}

<#
.SYNOPSIS
    Builds service health alert objects from query results.

.DESCRIPTION
    The `Build-WAFServiceHealthObject` function processes the results obtained from the Azure Resource Graph query and constructs custom objects representing service health alerts with relevant details.

.PARAMETER AdvQueryResult
    The results from the Azure Resource Graph query.

.INPUTS
    System.Object[]. Accepts an array of query result objects.

.OUTPUTS
    System.Object[]. Returns an array of service health alert objects with detailed properties.

.EXAMPLE
    # Process query results to get service health alert objects
    $queryResults = Invoke-WAFQuery -Query $Servicequery -SubscriptionIds $SubscriptionIds
    $serviceHealthAlerts = Build-WAFServiceHealthObject -AdvQueryResult $queryResults

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
function Build-WAFServiceHealthObject {
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $AdvQueryResult
    )

    $return = $AdvQueryResult.ForEach({ [ServiceHealthAlert]::new($_) })

    return $return
}


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
