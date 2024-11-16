Function Start-WARACollector {
    [CmdletBinding()]
    Param(
        [switch]$Debugging,
        [switch]$SAP,
        [switch]$AVD,
        [switch]$AVS,
        [switch]$HPC,
        [ValidateScript({ Test-WAFSubscriptionId $_ })]
        [String[]]$SubscriptionIds,
        [ValidateScript({ Test-WAFResourceGroupId $_ })]
        [String[]]$ResourceGroups,
        [ValidateScript({ Test-WAFIsGuid $_ })]
        [String]$TenantID,
        [ValidateScript({ Test-WAFTagPattern $_ })]
        [String[]]$Tags,
        [ValidateSet('AzureCloud', 'AzureUSGovernment')]
        $AzureEnvironment = 'AzureCloud',
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        $ConfigFile,
        [ValidatePattern('^https:\/\/.+$')]
        [string]$RepoUrl = 'https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2',
        # Runbook parameters...
        [switch]$UseImplicitRunbookSelectors,
        $RunbookFile
    )

    switch ($PSBoundParameters.Keys) {
        'ConfigFile' {
            if ($PSBoundParameters.Keys.Count -gt 1) { 
                throw "ConfigFile cannot be used with other parameters."
            } else {
                $ConfigData = Import-WAFConfigFileData -ConfigFile $ConfigFile
                Test-WAFIsGuid -StringGuid $ConfigData.TenantId
                if ($configdata.subscriptionids) { Test-WAFSubscriptionId -SubscriptionId $ConfigData.SubscriptionIds }
                if ($configdata.resourcegroups) { Test-WAFResourceGroupId -ResourceGroupId $ConfigData.ResourceGroups }
                if ($configdata.tags) { Test-WAFTagPattern -TagPattern $ConfigData.Tags }
            }
        #Add parameter logic here and test if the parameters are valid.
        }
    }

    #Use Null Coalescing to set the values of parameters.
    $Scope_TenantId = [String]$ConfigData.TenantId ?? $TenantID ?? (throw "Tenant ID is required.")
    $Scope_SubscriptionIds = $ConfigData.SubscriptionIds ?? $SubscriptionIds ??  @()
    $Scope_ResourceGroups = $ConfigData.ResourceGroups ?? $ResourceGroups ??  @()
    $Scope_Tags = $ConfigData.Tags ?? $Tags ?? @()

    #Import Recommendation Object from APRL
    $RecommendationObject = Invoke-RestMethod "https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/data/recommendations.json"

    #TODO: Test if the parameters are valid

    #Connect to Azure
    Connect-WAFAzure -TenantId $Scope_TenantId -AzureEnvironment $AzureEnvironment

    #Get Implicit Subscription Ids from Scope
    $Scope_ImplicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    
    #Get all tagged resource groups from the Implicit Subscription ID scope
    $Filter_TaggedResourceGroupIds = Get-WAFTaggedRGResources -tagArray $Scope_Tags -SubscriptionId $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')

    #Get all tagged resources from the Implicit Subscription ID scope
    $Filter_TaggedResourceIds = Get-WAFTaggedResources -tagArray $Scope_Tags -SubscriptionId $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '')

    #Get all APRL recommendations from the Implicit Subscription ID scope
    $Recommendations = Invoke-WAFQueryLoop -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '') -RecommendationObject $RecommendationObject
    
    #Create impactedResourceObj objects from the recommendations
    $impactedResourceObj = $Recommendations.ForEach({ [impactedResourceObj]::new($_) })

    #Filter impactedResourceObj objects by subscription, resourcegroup, and resource scope
    $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups

    #Filter impactedResourceObj objects by tagged resource group and resource scope
    $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds

    #Get Advisor Recommendations
    $advisorResourceObj = Get-WAFAdvisorRecommendations -Subid $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '') -HighAvailability

    #Filter Advisor Recommendations by subscription, resourcegroup, and resource scope
    $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups

    #Filter Advisor Recommendations by tagged resource group and resource scope
    $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds

    $outputJson = [PSCustomObject]@{
        impactedResources = $impactedResourceObj
        advisory          = $advisorResourceObj
    }

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
