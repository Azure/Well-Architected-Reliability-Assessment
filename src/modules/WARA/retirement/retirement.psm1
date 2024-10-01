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
            Starttime       = $retirementEvent.properties.impactStartTime
            Endtime         = $retirementEvent.properties.impactMitigationTime
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

# NOTE: This function should be placed in the utils.psm1, or implement a similar function in the utils.psm1.
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

# NOTE: This function should be placed in the utils.psm1.
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
        [datetime] $Starttime,

        [Parameter(Mandatory = $true)]
        [datetime] $Endtime,

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
        Starttime       = $Starttime.ToString('yyyy-MM-dd HH:mm:ss')
        Endtime         = $Endtime.ToString('yyyy-MM-dd HH:mm:ss')
        Level           = $Level
        Title           = $Title
        Summary         = $Summary
        Header          = $Header
        ImpactedService = $ImpactedService -join ', '
        Description     = $Description
    }
}
