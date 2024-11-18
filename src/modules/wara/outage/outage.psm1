<#
.SYNOPSIS
    Retrieves recent outage service issue events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to recent outage service issue events.
    It includes the following functions:
    - Get-WAFOutage
    - Invoke-AzureRestApi
    - Get-AzureRestMethodUriPath
    - New-WAFOutageObject

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionId '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23

    This module requires the Az.Accounts module to be installed and imported.
#>

<#
.SYNOPSIS
    Retrieves recent outage events for a given Azure subscription.

.DESCRIPTION
    The Get-WAFOutage function queries the Microsoft Resource Health API to retrieve recent outage events for a specified Azure subscription. It filters the events to include only those that have updated in the last three months.

.PARAMETER SubscriptionId
    The subscription ID for the Azure subscription to retrieve outage events.

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

.OUTPUTS
    Returns a list of outage events, including the name and properties of each event.

.EXAMPLE
    PS> $outageObjects = Get-WAFOutage -SubscriptionId '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent outage events for the specified Azure subscription.

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23

    This function requires the Az.Accounts module to be installed and imported.
#>
function Get-WAFOutage {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string[]] $SubscriptionIds
    )

    # NOTE:
    # ARG query with ServiceHealthResources returns last 3 months of events.
    # Azure portal shows last 3 months of events maximum.

    $outageObjects = @()

    foreach($SubscriptionId in $SubscriptionId) {
 
    $cmdletParams = @{
        Method               = 'GET'
        SubscriptionId       = $SubscriptionId
        ResourceProviderName = 'Microsoft.ResourceHealth'
        ResourceType         = 'events'
        ApiVersion           = '2024-02-01'
        QueryString          = @(
            ('queryStartTime={0}' -f (Get-Date).AddMonths(-3).ToString('yyyy-MM-ddT00:00:00')),
            '$filter=(properties/eventType eq ''ServiceIssue'')'
        ) -join '&'
    }
    $response = Invoke-AzureRestApi @cmdletParams
    $serviceIssueEvents = ($response.Content | ConvertFrom-Json).value

    $return = foreach ($serviceIssueEvent in $serviceIssueEvents) {
        $cmdletParams = @{
            SubscriptionId  = $SubscriptionId
            TrackingId      = $serviceIssueEvent.name
            Status          = $serviceIssueEvent.properties.status
            LastUpdateTime  = $serviceIssueEvent.properties.lastUpdateTime
            StartTime       = $serviceIssueEvent.properties.impactStartTime
            EndTime         = $serviceIssueEvent.properties.impactMitigationTime
            Level           = $serviceIssueEvent.properties.level
            Title           = $serviceIssueEvent.properties.title
            Summary         = $serviceIssueEvent.properties.summary
            Header          = $serviceIssueEvent.properties.header
            ImpactedService = $serviceIssueEvent.properties.impact.impactedService
            Description     = $serviceIssueEvent.properties.description
        }
        New-WAFOutageObject @cmdletParams
    }
    $outageObjects += $return
}
    return $outageObjects
}

<#
.SYNOPSIS
    Invokes an Azure REST API then returns the response.

.DESCRIPTION
    The Invoke-AzureRestApi function invokes an Azure REST API with the specified parameters then return the response.

.PARAMETER Method
    The HTTP method to invoke the Azure REST API. The accepted values are GET, POST, PUT, PATCH, and DELETE.

.PARAMETER SubscriptionId
    The subscription ID that constitutes the URI for invoke the Azure REST API.

.PARAMETER ResourceGroupName
    The resource group name that constitutes the URI for invoke the Azure REST API.

.PARAMETER ResourceProviderName
    The resource provider name that constitutes the URI for invoke the Azure REST API. It's usually as the XXXX.XXXX format.

.PARAMETER ResourceType
    The resource type that constitutes the URI for invoke the Azure REST API.

.PARAMETER Name
    The resource name that constitutes the URI for invoke the Azure REST API.

.PARAMETER ApiVersion
    The Azure REST API version that constitutes the URI for invoke the Azure REST API. It's usually as the yyyy-mm-dd format.

.PARAMETER QueryString
    The query string that constitutes the URI for invoke the Azure REST API.

.PARAMETER RequestBody
    The request body for invoke the Azure REST API.

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

.OUTPUTS
    Returns a REST API response as the PSHttpResponse.

.EXAMPLE
    PS> $response = Invoke-AzureRestApi -Method 'GET' -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceProviderName 'Microsoft.ResourceHealth' -ResourceType 'events' -ApiVersion '2024-02-01' -QueryString 'queryStartTime=2024-10-02T00:00:00'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23

    This function requires the Az.Accounts module to be installed and imported.
    This function should be placed in a common module such as a utility/helper module because the capability of this function is common across modules.
#>
function Invoke-AzureRestApi {
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Profile.Models.PSHttpResponse])]
    param (
        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string] $Method,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [ValidateLength(1, 90)]
        [string] $ResourceGroupName,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $ResourceProviderName,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [string] $Name,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [ValidatePattern('^[0-9]{4}(-[0-9]{2}){2}$')]
        [string] $ApiVersion,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $false)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $false)]
        [string] $QueryString,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $false)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $false)]
        [string] $RequestBody
    )

    # Built the Azure REST API URI path.
    $cmdletParams = @{
        SubscriptionId       = $SubscriptionId
        ResourceProviderName = $ResourceProviderName
        ResourceType         = $ResourceType
        ApiVersion           = $ApiVersion
    }
    if ($PSBoundParameters.ContainsKey('ResourceGroupName')) { $cmdletParams.ResourceGroupName = $ResourceGroupName }
    if ($PSBoundParameters.ContainsKey('Name')) { $cmdletParams.Name = $Name}
    if ($PSBoundParameters.ContainsKey('QueryString')) { $cmdletParams.QueryString = $QueryString }
    $path = Get-AzureRestMethodUriPath @cmdletParams

    # Invoke the Azure REST API using the URI path.
    $cmdletParams = @{
        Method = $Method
        Path   = $path
    }
    if ($PSBoundParameters.ContainsKey('RequestBody')) { $cmdletParams.Payload = $RequestBody }
    return Invoke-AzRestMethod @cmdletParams
}

<#
.SYNOPSIS
    Retrieves the path of the Azure REST API URI.

.DESCRIPTION
    The Get-AzureRestMethodUriPath function retrieves the formatted path of the Azure REST API URI based on the specified URI parts as parameters.
    The path represents the Azure REST API URI without the protocol (e.g. https), host (e.g. management.azure.com). For example,
    /subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/stsample1234?api-version=2024-01-01

.PARAMETER SubscriptionId
    The subscription ID that constitutes the path of Azure REST API URI.

.PARAMETER ResourceGroupName
    The resource group name that constitutes the path of Azure REST API URI.

.PARAMETER ResourceProviderName
    The resource provider name that constitutes the path of Azure REST API URI. It's usually as the XXXX.XXXX format.

.PARAMETER ResourceType
    The resource type that constitutes the path of Azure REST API URI.

.PARAMETER Name
    The resource name that constitutes the path of Azure REST API URI.

.PARAMETER ApiVersion
    The Azure REST API version that constitutes the path of Azure REST API URI. It's usually as the yyyy-mm-dd format.

.PARAMETER QueryString
    The query string that constitutes the path of Azure REST API URI.

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

.OUTPUTS
    Returns a URI path to call Azure REST API.

.EXAMPLE
    PS> $path = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceGroupName 'rg1' -ResourceProviderName 'Microsoft.Storage' -ResourceType 'storageAccounts' -Name 'stsample1234' -ApiVersion '2024-01-01' -QueryString 'param1=value1'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23

    This function should be placed in a common module such as a utility/helper module because the capability of this function is common across modules.
#>
function Get-AzureRestMethodUriPath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [ValidateLength(1, 90)]
        [string] $ResourceGroupName,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $ResourceProviderName,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $ResourceType,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [string] $Name,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [ValidatePattern('^[0-9]{4}(-[0-9]{2}){2}$')]
        [string] $ApiVersion,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $false)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $false)]
        [string] $QueryString
    )

    $additionalQueryString = if ($PSBoundParameters.ContainsKey('QueryString')) { '&' + $QueryString } else { '' }
    $path = if ($PSCmdlet.ParameterSetName -eq 'WithResourceGroup') {
        '/subscriptions/{0}/resourcegroups/{1}/providers/{2}/{3}/{4}?api-version={5}{6}' -f $SubscriptionId, $ResourceGroupName, $ResourceProviderName, $ResourceType, $Name, $ApiVersion, $additionalQueryString
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'WithoutResourceGroup') {
        '/subscriptions/{0}/providers/{1}/{2}?api-version={3}{4}' -f $SubscriptionId, $ResourceProviderName, $ResourceType, $ApiVersion, $additionalQueryString
    }
    else {
        throw 'Invalid ParameterSetName'
    }
    return $path
}

<#
.SYNOPSIS
    Creates an outage object.

.DESCRIPTION
    The New-WAFOutageObject function creates an outage object based on the specified parameters.

.PARAMETER SubscriptionId
    The subscription ID of the outage event.

.PARAMETER TrackingId
    The tracking ID of the outage event. It's usually as the XXXX-XXX format.

.PARAMETER Status
    The status of the outage event. It's usually Active or Resolved.

.PARAMETER LastUpdateTime
    The last update time of the outage event.

.PARAMETER StartTime
    The impact start time of the outage event.

.PARAMETER EndTime
    The impact mitigation time of the outage event.

.PARAMETER Level
    The level of the outage event such as Warning, etc.

.PARAMETER Title
    The title of the outage event.

.PARAMETER Summary
    The summary of the outage event.

.PARAMETER Header
    The header of the outage event.

.PARAMETER ImpactedService
    The impacted services of the outage event.

.PARAMETER Description
    The description of the outage event.

.PARAMETER ProgressAction
    This is a common parameter, but this cmdlet does not use this parameter.

.OUTPUTS
    Returns an OutageObject as a PSCustomObject.

.EXAMPLE
    PS> $outageObject = New-WAFOutageObject -SubscriptionId $subscriptionId -TrackingId 'XXXX-XXX' -Status 'Active' -LastUpdateTime $lastUpdateTime -StartTime $startTime -EndTime $endTime -Level 'Warning' -Title $title -Summary $summary -Header $header -ImpactedService $impactedServices -Description $description

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-23
#>
function New-WAFOutageObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string] $TrackingId,

        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [datetime] $LastUpdateTime,

        [Parameter(Mandatory = $true)]
        [datetime] $StartTime,

        [Parameter(Mandatory = $true)]
        [datetime] $EndTime,

        [Parameter(Mandatory = $true)]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $Title,

        [Parameter(Mandatory = $true)]
        [string] $Summary,

        [Parameter(Mandatory = $true)]
        [string] $Header,

        [Parameter(Mandatory = $true)]
        [string[]] $ImpactedService,

        [Parameter(Mandatory = $true)]
        [string] $Description
    )

    return [PSCustomObject] @{
        Subscription    = $SubscriptionId
        TrackingId      = $TrackingId
        Status          = $Status
        LastUpdateTime  = $LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
        StartTime       = $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
        EndTime         = $EndTime.ToString('yyyy-MM-dd HH:mm:ss')
        Level           = $Level
        Title           = $Title
        Summary         = $Summary
        Header          = $Header
        ImpactedService = $ImpactedService -join ', '
        Description     = $Description
    }
}
