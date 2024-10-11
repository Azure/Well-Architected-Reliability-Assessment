<#
.SYNOPSIS
    Retrieves active retirement health advisory events.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to active retirement health advisory events.
    It includes the following functions:
    - Get-WAFResourceRetirement
    - Invoke-AzureRestApi
    - Get-AzureRestMethodUriPath
    - New-WAFResourceRetirementObject

.EXAMPLE
    $retirementObjects = Get-WAFResourceRetirement -SubscriptionId '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02
#>

<#
.SYNOPSIS
    Retrieves active retirement health advisory events based on the specified subscription ID.

.DESCRIPTION
    The Get-WAFResourceRetirement function takes a subscription ID and retrieves active retirement health advisory events.

.PARAMETER SubscriptionId
    A subscription ID to retrieves active retirement health advisory events.

.EXAMPLE
    $retirementObjects = Get-WAFResourceRetirement -SubscriptionId '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02
#>
function Get-WAFResourceRetirement {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId
    )

    # NOTE:
    # ARG query with ServiceHealthResources returns last 3 months of events.
    # Azure portal shows last 1 months of events.
    $cmdletParams = @{
        Method               = 'GET'
        SubscriptionId       = $SubscriptionId
        ResourceProviderName = 'Microsoft.ResourceHealth'
        ResourceType         = 'events'
        ApiVersion           = '2024-02-01'
        QueryString          = @(
            ('queryStartTime={0}' -f (Get-Date).AddMonths(-3).ToString('yyyy-MM-ddT00:00:00')),
            '$filter=(properties/eventType eq ''HealthAdvisory'') and (properties/eventSubType eq ''Retirement'') and (Properties/Status eq ''Active'')'
        ) -join '&'
    }
    $response = Invoke-AzureRestApi @cmdletParams
    $retirementEvents = ($response.Content | ConvertFrom-Json).value

    $retirementObjects = foreach ($retirementEvent in $retirementEvents) {
        $cmdletParams = @{
            SubscriptionId  = $SubscriptionId
            TrackingId      = $retirementEvent.name
            Status          = $retirementEvent.properties.status
            LastUpdateTime  = $retirementEvent.properties.lastUpdateTime
            StartTime       = $retirementEvent.properties.impactStartTime
            EndTime         = $retirementEvent.properties.impactMitigationTime
            Level           = $retirementEvent.properties.level
            Title           = $retirementEvent.properties.title
            Summary         = $retirementEvent.properties.summary
            Header          = $retirementEvent.properties.header
            ImpactedService = $retirementEvent.properties.impact.impactedService
            Description     = $retirementEvent.properties.description
        }
        New-WAFResourceRetirementObject @cmdletParams
    }

    return $retirementObjects
}

<#
.SYNOPSIS
    Invokes an Azure REST API then returns the response.

.DESCRIPTION
    The Invoke-AzureRestApi function invokes an Azure REST API with the specified parameters then return the response.

.PARAMETER Method
    The HTTP method to invoke the Azure REST API.

.PARAMETER SubscriptionId
    The subscription ID that constitutes the URI for invoke the Azure REST API.

.PARAMETER ResourceGroupName
    The resource group name that constitutes the URI for invoke the Azure REST API.

.PARAMETER ResourceProviderName
    The resource provider name that constitutes the URI for invoke the Azure REST API.

.PARAMETER ResourceType
    The resource type that constitutes the URI for invoke the Azure REST API.

.PARAMETER Name
    The resource name that constitutes the URI for invoke the Azure REST API.

.PARAMETER ApiVersion
    The Azure REST API version that constitutes the URI for invoke the Azure REST API.

.PARAMETER QueryString
    The query string that constitutes the URI for invoke the Azure REST API.

.PARAMETER RequestBody
    The request body for invoke the Azure REST API.

.EXAMPLE
    $response = Invoke-AzureRestApi -Method 'GET' -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceProviderName 'Microsoft.ResourceHealth' -ResourceType 'events' -ApiVersion '2024-02-01' -QueryString 'queryStartTime=2024-10-02T00:00:00'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02

    This function should be placed in a common module such as a utility module because this is common feature across modules.
#>
function Invoke-AzureRestApi {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $Method,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $SubscriptionId,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
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
    The resource provider name that constitutes the path of Azure REST API URI.

.PARAMETER ResourceType
    The resource type that constitutes the path of Azure REST API URI.

.PARAMETER Name
    The resource name that constitutes the path of Azure REST API URI.

.PARAMETER ApiVersion
    The Azure REST API version that constitutes the path of Azure REST API URI.

.PARAMETER QueryString
    The query string that constitutes the path of Azure REST API URI.

.EXAMPLE
    $path = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceGroupName 'rg1' -ResourceProviderName 'Microsoft.Storage' -ResourceType 'storageAccounts' -Name 'stsample1234' -ApiVersion '2024-01-01'

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02

    This function should be placed in a common module such as a utility module because this is common feature across modules.
#>
function Get-AzureRestMethodUriPath {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
        [Parameter(ParameterSetName = 'WithoutResourceGroup', Mandatory = $true)]
        [string] $SubscriptionId,

        [Parameter(ParameterSetName = 'WithResourceGroup', Mandatory = $true)]
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
    Creates a retirement object.

.DESCRIPTION
    The New-WAFResourceRetirementObject function creates a retirement object based on the specified parameters.

.PARAMETER SubscriptionId
    The subscription ID of the retirement event.

.PARAMETER TrackingId
    The tracking ID of the retirement event.

.PARAMETER Status
    The status of the retirement event.

.PARAMETER LastUpdateTime
    The last update time of the retirement event.

.PARAMETER StartTime
    The impact start time of the retirement event.

.PARAMETER EndTime
    The impact mitigation time of the retirement event.

.PARAMETER Level
    The level of the retirement event.

.PARAMETER Title
    The title of the retirement event.

.PARAMETER Summary
    The summary of the retirement event.

.PARAMETER Header
    The header of the retirement event.

.PARAMETER ImpactedService
    The impacted services of the retirement event.

.PARAMETER Description
    The description of the retirement event.

.EXAMPLE
    retirementObject = New-WAFResourceRetirementObject -SubscriptionId $subscriptionId -TrackingId $trackingId -Status $status -LastUpdateTime $lastUpdateTime -StartTime $startTime -EndTime $endTime -Level $level -Title $title -Summary $summary -Header $header -ImpactedService $impactedServices -Description $description

.NOTES
    Author: Takeshi Katano
    Date: 2024-10-02
#>
function New-WAFResourceRetirementObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
