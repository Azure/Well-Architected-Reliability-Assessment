function Start-WARACollector {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default')]
        [switch] $Debugging,

        [Parameter(ParameterSetName = 'Default')]
        [switch] $SAP,

        [Parameter(ParameterSetName = 'Default')]
        [switch] $AVD,

        [Parameter(ParameterSetName = 'Default')]
        [switch] $AVS,

        [Parameter(ParameterSetName = 'Default')]
        [switch] $HPC,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFSubscriptionId $_ })]
        [string[]] $SubscriptionIds,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFResourceGroupId $_ })]
        [string[]] $ResourceGroups,

        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFIsGuid $_ })]
        [string] $TenantID,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFTagPattern $_ })]
        [string[]] $Tags,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
        [string] $AzureEnvironment = 'AzureCloud',

        [Parameter(ParameterSetName = 'ConfigFileSet', Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $ConfigFile,

        [Parameter(ParameterSetName = 'Default')]
        [ValidatePattern('^https:\/\/.+$')]
        [string] $RecommendationDataUri = 'https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/data/recommendations.json',

        # Runbook parameters...
        [Parameter(ParameterSetName = 'Default')]
        [switch] $UseImplicitRunbookSelectors,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $RunbookFile
    )

    Write-Debug 'Debugging mode is enabled'

    # Determine which parameter set is active
    switch ($PSCmdlet.ParameterSetName) {
        'ConfigFileSet' {
            Write-Debug 'Using ConfigFileSet parameter set'
            Write-Debug "ConfigFile: $ConfigFile"
            Write-Debug 'Importing ConfigFile data'
            $ConfigData = Import-WAFConfigFileData -ConfigFile $ConfigFile
            Write-Debug 'Testing TenantId, SubscriptionIds, ResourceGroups, and Tags'
            Test-WAFIsGuid -StringGuid $ConfigData.TenantId
            $ConfigData.TenantId = ([guid][string]$ConfigData.TenantId).Guid
            $null = if ($ConfigData.SubscriptionIds) { Test-WAFSubscriptionId -InputValue $ConfigData.SubscriptionIds }
            $null = if ($ConfigData.ResourceGroups) { Test-WAFResourceGroupId -InputValue $ConfigData.ResourceGroups }
            $null = if ($ConfigData.Tags) { Test-WAFTagPattern -InputValue $ConfigData.Tags }
        }
        'Default' {
            Write-Debug 'Using Default parameter set'
        }
    }

    #Use Null Coalescing to set the values of parameters.
    $Scope_TenantId = $ConfigData.TenantId ?? $TenantID ?? (throw 'Tenant ID is required.')
    $Scope_SubscriptionIds = $ConfigData.SubscriptionIds ?? $SubscriptionIds ?? @()
    $Scope_ResourceGroups = $ConfigData.ResourceGroups ?? $ResourceGroups ?? @()
    $Scope_Tags = $ConfigData.Tags ?? $Tags ?? @()

    $Scope_SubscriptionIds = Repair-WAFSubscriptionId -SubscriptionIds $Scope_SubscriptionIds

    Write-Debug "Tenant ID: $Scope_TenantId"
    Write-Debug "Subscription IDs: $Scope_SubscriptionIds"
    Write-Debug "Resource Groups: $Scope_ResourceGroups"
    Write-Debug "Tags: $Scope_Tags"

    #Import Recommendation Object from APRL
    $RecommendationObject = Invoke-RestMethod $RecommendationDataUri

    #TODO: Test if the parameters are valid

    #Connect to Azure
    Write-Debug 'Connecting to Azure if not connected.'
    Connect-WAFAzure -TenantId $Scope_TenantId -AzureEnvironment $AzureEnvironment

    #Get Implicit Subscription Ids from Scope
    Write-Debug 'Getting Implicit Subscription Ids from Scope'
    $Scope_ImplicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Implicit Subscription Ids: $Scope_ImplicitSubscriptionIds"

    #Get all resources from the Implicit Subscription ID scope - We use this later to add type, location, subscriptionid, resourcegroup to the impactedResourceObj objects
    Write-Debug 'Getting all resources from the Implicit Subscription ID scope'
    $AllResources = Invoke-WAFQuery -subscriptionIds $Scope_SubscriptionIds.replace('/subscriptions/', '')
    Write-Debug "Count of Resources: $($AllResources.count)"

    #Create HashTable of all resources for faster lookup
    Write-Debug 'Creating HashTable of all resources for faster lookup'
    $AllResourcesHash = @{}
    $AllResources.ForEach({ $AllResourcesHash[$_.id] = $_ })
    Write-Debug "All Resources Hash: $($AllResourcesHash).count"

    #Get all APRL recommendations from the Implicit Subscription ID scope
    Write-Debug 'Getting all APRL recommendations from the Implicit Subscription ID scope'
    $Recommendations = Invoke-WAFQueryLoop -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '') -RecommendationObject $RecommendationObject
    Write-Debug "Count of Recommendations: $($Recommendations.count)"

    #Create impactedResourceObj objects from the recommendations
    Write-Debug 'Creating impactedResourceObj objects from the recommendations'
    #$impactedResourceObj = $Recommendations.ForEach({ [impactedResourceObj]::new($_) })
    $impactedResourceObj = Build-impactedResourceObj -impactedResource $Recommendations -allResources $AllResourcesHash -RecommendationObject $RecommendationObject
    Write-Debug "Count of impactedResourceObj objects: $($impactedResourceObj.count)"

    #Filter impactedResourceObj objects by subscription, resourcegroup, and resource scope
    Write-Debug 'Filtering impactedResourceObj objects by subscription, resourcegroup, and resource scope'
    $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of filtered impactedResourceObj objects: $($impactedResourceObj.count)"

    #Get Advisor Recommendations
    Write-Debug 'Getting Advisor Recommendations'
    $advisorResourceObj = Get-WAFAdvisorRecommendation -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '') -HighAvailability
    Write-Debug "Count of Advisor Recommendations: $($advisorResourceObj.count)"

    #Filter Advisor Recommendations by subscription, resourcegroup, and resource scope
    Write-Debug 'Filtering Advisor Recommendations by subscription, resourcegroup, and resource scope'
    $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of filtered Advisor Recommendations: $($advisorResourceObj.count)"

    #If we passed tags, filter impactedResourceObj and advisorResourceObj by tagged resource group and tagged resource scope
    if (![string]::IsNullOrEmpty($Scope_Tags)) {

        Write-Debug 'Starting Tag Filtering'
        Write-Debug "Scope Tags: $Scope_Tags"

        #Get all tagged resource groups from the Implicit Subscription ID scope
        Write-Debug 'Getting all tagged resource groups from the Implicit Subscription ID scope'
        $Filter_TaggedResourceGroupIds = Get-WAFTaggedResourceGroup -tagArray $Scope_Tags -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')
        Write-Debug "Count of Tagged Resource Group Ids: $($Filter_TaggedResourceGroupIds.count)"

        #Get all tagged resources from the Implicit Subscription ID scope
        Write-Debug 'Getting all tagged resources from the Implicit Subscription ID scope'
        $Filter_TaggedResourceIds = Get-WAFTaggedResource -tagArray $Scope_Tags -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')
        Write-Debug "Count of Tagged Resource Ids: $($Filter_TaggedResourceIds.count)"

        #Filter impactedResourceObj objects by tagged resource group and resource scope
        Write-Debug 'Filtering impactedResourceObj objects by tagged resource group and resource scope'
        $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds
        Write-Debug "Count of tag filtered impactedResourceObj objects: $($impactedResourceObj.count)"

        #Filter Advisor Recommendations by tagged resource group and resource scope
        Write-Debug 'Filtering Advisor Recommendations by tagged resource group and resource scope'
        $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds
        Write-Debug "Count of tag filtered Advisor Recommendations: $($advisorResourceObj.count)"
    }

    #Get Azure Outages
    Write-Debug 'Getting Azure Outages'
    $outageResourceObj = Get-WAFOutage -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')

    #Get Azure Retirements
    Write-Debug 'Getting Azure Retirements'
    $retirementResourceObj = Get-WAFResourceRetirement -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')

    #Get Azure Support Tickets
    Write-Debug 'Getting Azure Support Tickets'
    $supportTicketObjects = Get-WAFSupportTicket -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')

    #Get Azure Service Health
    Write-Debug 'Getting Azure Service Health'
    $serviceHealthObjects = Get-WAFServiceHealth -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')

    #Create output JSON
    Write-Debug 'Creating output JSON'
    $outputJson = [PSCustomObject]@{
        impactedResources = $impactedResourceObj
        advisory          = $advisorResourceObj
        outages           = $outageResourceObj
        retirements       = $retirementResourceObj
        supportTickets    = $supportTicketObjects
        serviceHealth     = $serviceHealthObjects
    }

    Write-Debug 'Output JSON'
    return $outputJson
}

function Build-impactedResourceObj {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject] $impactedResources,

        [Parameter(Mandatory = $true)]
        [hashtable] $allResources,

        [Parameter(Mandatory = $true)]
        [PSObject] $RecommendationObject
    )

    $r = foreach ($impacted in $impactedResources) {
        [impactedResourceObj]::new($impacted, $allResources).createValidationObject($RecommendationObject)
    }
    return $r
}

class resourceObj {
    <# Define the class. Try constructors, properties, or methods. #>
    [string] $validationAction
    [string] $recommendationId
    [string] $name
    [string] $id
    [string] $type
    [string] $location
    [string] $subscriptionId
    [string] $resourceGroup
    [string] $param1
    [string] $param2
    [string] $param3
    [string] $param4
    [string] $param5
    [string] $checkName
    [string] $selector
}

class impactedResourceObj : resourceObj {
    impactedResourceObj([PSObject]$impactedResource, [hashtable]$allResources) {
        $this.validationAction = "Azure Resource Graph"
        $this.RecommendationId = $impactedResource.recommendationId
        $this.Name = $impactedResource.name
        $this.Id = $impactedResource.id
        $this.type = $allResources[$this.id].type ?? "Unknown"
        $this.location = $allResources[$this.id].location ?? "Unknown"
        $this.subscriptionId = $allResources[$this.id].subscriptionId ?? $this.id.split("/")[2] ?? "Unknown"
        $this.resourceGroup = $allResources[$this.id].resourceGroup ?? $this.id.split("/")[4] ?? "Unknown"
        $this.Param1 = $impactedResource.param1
        $this.Param2 = $impactedResource.param2
        $this.Param3 = $impactedResource.param3
        $this.Param4 = $impactedResource.param4
        $this.Param5 = $impactedResource.param5
        $this.checkName = $impactedResource.checkName
        $this.selector = $impactedResource.selector ?? "APRL" 
    }

    [object] createValidationObject([PSObject]$RecommendationObject) {
        $return = @($this)
        $recommendationByType = $recommendationObject.where({ $_.recommendationResourceType -eq $this.type -and $_.recommendationMetadataState -eq "Active" -and $_.automationavailable -eq $false })
        foreach ($rec in $recommendationByType) {
            $r = [resourceObj]::new()
            $r.validationAction = [impactedResourceObj]::getValidationAction($rec.query)
            $r.recommendationId = $rec.aprlGuid
            $r.name = $this.name
            $r.id = $this.id
            $r.type = $this.type
            $r.location = $this.location
            $r.subscriptionId = $this.subscriptionId
            $r.resourceGroup = $this.resourceGroup
            $r.param1 = ''
            $r.param2 = ''
            $r.param3 = ''
            $r.param4 = ''
            $r.param5 = ''
            $r.checkName = $this.checkName
            $r.selector = $this.selector
            $return += $r
        }
        return $return
    }

    static [string] getValidationAction($query) {
        $return = switch -wildcard ($query) {
            "*development*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "*cannot-be-validated-with-arg*" { 'IMPORTANT - Recommendation cannot be validated with ARGs - Validate Resources manually' }
            "*Azure Resource Graph*" { 'IMPORTANT - This resource has a query but the automation is not available - Validate Resources manually' }
            default { "Unknown" }
        }
        return $return
    }
}
