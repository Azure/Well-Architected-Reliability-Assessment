Function Start-WARACollector {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default')]
        [switch]$Debugging,

        [Parameter(ParameterSetName = 'Default')]
        [switch]$SAP,

        [Parameter(ParameterSetName = 'Default')]
        [switch]$AVD,

        [Parameter(ParameterSetName = 'Default')]
        [switch]$AVS,

        [Parameter(ParameterSetName = 'Default')]
        [switch]$HPC,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFSubscriptionId $_ })]
        [String[]]$SubscriptionIds,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFResourceGroupId $_ })]
        [String[]]$ResourceGroups,

        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFIsGuid $_ })]
        [String]$TenantID,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-WAFTagPattern $_ })]
        [String[]]$Tags,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
        [string]$AzureEnvironment = 'AzureCloud',

        [Parameter(ParameterSetName = 'ConfigFileSet', Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$ConfigFile,

        [Parameter(ParameterSetName = 'Default')]
        [ValidatePattern('^https:\/\/.+$')]
        [string]$RepoUrl = 'https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2',

        # Runbook parameters...
        [Parameter(ParameterSetName = 'Default')]
        [switch]$UseImplicitRunbookSelectors,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$RunbookFile
    )

    Write-Debug "Debugging mode is enabled"

    # Determine which parameter set is active
    switch ($PSCmdlet.ParameterSetName) {
        'ConfigFileSet' {
            Write-Debug "Using ConfigFileSet parameter set"
            Write-Debug "ConfigFile: $ConfigFile"
            Write-Debug "Importing ConfigFile data"
            $ConfigData = Import-WAFConfigFileData -ConfigFile $ConfigFile
            Write-Debug "Testing TenantId, SubscriptionIds, ResourceGroups, and Tags"
            Test-WAFIsGuid -StringGuid $ConfigData.TenantId
            $ConfigData.TenantId = ([guid][string]$ConfigData.TenantId).Guid
            $null =if ($ConfigData.SubscriptionIds) { Test-WAFSubscriptionId -SubscriptionId $ConfigData.SubscriptionIds }
            $null =if ($ConfigData.ResourceGroups) { Test-WAFResourceGroupId -ResourceGroupId $ConfigData.ResourceGroups }
            $null =if ($ConfigData.Tags) { Test-WAFTagPattern -TagPattern $ConfigData.Tags }
        }
        'Default' {
            Write-Debug "Using Default parameter set"
            
        }
    }



    #Use Null Coalescing to set the values of parameters.
    $Scope_TenantId = $ConfigData.TenantId ?? $TenantID ?? (throw "Tenant ID is required.")
    $Scope_SubscriptionIds = $ConfigData.SubscriptionIds ?? $SubscriptionIds ?? @()
    $Scope_ResourceGroups = $ConfigData.ResourceGroups ?? $ResourceGroups ?? @()
    $Scope_Tags = $ConfigData.Tags ?? $Tags ?? @()

    $Scope_SubscriptionIds = Repair-WAFSubscriptionId -SubscriptionIds $Scope_SubscriptionIds

    Write-Debug "Tenant ID: $Scope_TenantId"
    Write-Debug "Subscription IDs: $Scope_SubscriptionIds"
    Write-Debug "Resource Groups: $Scope_ResourceGroups"
    Write-Debug "Tags: $Scope_Tags"

    

    #Import Recommendation Object from APRL
    $RecommendationObject = Invoke-RestMethod "https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/data/recommendations.json"

    #TODO: Test if the parameters are valid

    #Connect to Azure
    Write-Debug "Connecting to Azure if not connected."
    Connect-WAFAzure -TenantId $Scope_TenantId -AzureEnvironment $AzureEnvironment

    #Get Implicit Subscription Ids from Scope
    Write-Debug "Getting Implicit Subscription Ids from Scope"
    $Scope_ImplicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Implicit Subscription Ids: $Scope_ImplicitSubscriptionIds"

    #Get all APRL recommendations from the Implicit Subscription ID scope
    Write-Debug "Getting all APRL recommendations from the Implicit Subscription ID scope"
    $Recommendations = Invoke-WAFQueryLoop -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '') -RecommendationObject $RecommendationObject
    Write-Debug "Count of Recommendations: $($Recommendations.count)"

    #Create impactedResourceObj objects from the recommendations
    Write-Debug "Creating impactedResourceObj objects from the recommendations"
    $impactedResourceObj = $Recommendations.ForEach({ [impactedResourceObj]::new($_) })
    Write-Debug "Count of impactedResourceObj objects: $($impactedResourceObj.count)"

    #Filter impactedResourceObj objects by subscription, resourcegroup, and resource scope
    Write-Debug "Filtering impactedResourceObj objects by subscription, resourcegroup, and resource scope"
    $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of filtered impactedResourceObj objects: $($impactedResourceObj.count)"

    #Get Advisor Recommendations
    Write-Debug "Getting Advisor Recommendations"
    $advisorResourceObj = Get-WAFAdvisorRecommendation -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '') -HighAvailability
    Write-Debug "Count of Advisor Recommendations: $($advisorResourceObj.count)"

    #Filter Advisor Recommendations by subscription, resourcegroup, and resource scope
    Write-Debug "Filtering Advisor Recommendations by subscription, resourcegroup, and resource scope"
    $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of filtered Advisor Recommendations: $($advisorResourceObj.count)"

    #If we passed tags, filter impactedResourceObj and advisorResourceObj by tagged resource group and tagged resource scope
    if (![String]::IsNullOrEmpty($Scope_Tags)) {

        Write-Debug "Starting Tag Filtering"
        Write-Debug "Scope Tags: $Scope_Tags"

        #Get all tagged resource groups from the Implicit Subscription ID scope
        Write-Debug "Getting all tagged resource groups from the Implicit Subscription ID scope"
        $Filter_TaggedResourceGroupIds = Get-WAFTaggedResourceGroup -tagArray $Scope_Tags -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')
        Write-Debug "Count of Tagged Resource Group Ids: $($Filter_TaggedResourceGroupIds.count)"

        #Get all tagged resources from the Implicit Subscription ID scope
        Write-Debug "Getting all tagged resources from the Implicit Subscription ID scope"
        $Filter_TaggedResourceIds = Get-WAFTaggedResource -tagArray $Scope_Tags -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')
        Write-Debug "Count of Tagged Resource Ids: $($Filter_TaggedResourceIds.count)"

        #Filter impactedResourceObj objects by tagged resource group and resource scope
        Write-Debug "Filtering impactedResourceObj objects by tagged resource group and resource scope"
        $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds
        Write-Debug "Count of tag filtered impactedResourceObj objects: $($impactedResourceObj.count)"

        #Filter Advisor Recommendations by tagged resource group and resource scope
        Write-Debug "Filtering Advisor Recommendations by tagged resource group and resource scope"
        $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds
        Write-Debug "Count of tag filtered Advisor Recommendations: $($advisorResourceObj.count)"
    }

    #Get Azure Outages
    Write-Debug "Getting Azure Outages"
    $outageResourceObj = Get-WAFOutage -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')

    #Get Azure Retirements
    Write-Debug "Getting Azure Retirements"
    $retirementResourceObj = Get-WAFResourceRetirement -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')

    #Get Azure Support Tickets
    Write-Debug "Getting Azure Support Tickets"
    $supportTicketObjects = Get-WAFSupportTicket -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')

    #Get Azure Service Health
    Write-Debug "Getting Azure Service Health"
    $serviceHealthObjects = Get-WAFServiceHealth -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')

    #Create output JSON
    Write-Debug "Creating output JSON"
    $outputJson = [PSCustomObject]@{
        impactedResources = $impactedResourceObj
        advisory          = $advisorResourceObj
        outages           = $outageResourceObj
        retirements       = $retirementResourceObj
        supportTickets    = $supportTicketObjects
        serviceHealth     = $serviceHealthObjects
    }

    Write-Debug "Output JSON"
    return $outputJson

}



class impactedResourceObj {
    <# Define the class. Try constructors, properties, or methods. #>
    [string]    $validationAction
    [string]    $recommendationId
    [string]    $name
    [string]    $id
    [string]    $param1
    [string]    $param2
    [string]    $param3
    [string]    $param4
    [string]    $param5
    [string]    $checkName
    [string]    $selector

    impactedResourceObj([PSObject]$psObject) {
        $this.validationAction = "Azure Resource Graph"
        $this.RecommendationId = $psObject.recommendationId
        $this.Name = $psObject.name
        $this.Id = $psObject.id
        $this.Param1 = $psObject.param1
        $this.Param2 = $psObject.param2
        $this.Param3 = $psObject.param3
        $this.Param4 = $psObject.param4
        $this.Param5 = $psObject.param5
        $this.checkName = $psObject.checkName
        $this.selector = $psObject.selector ?? "APRL"
        
    }
}
