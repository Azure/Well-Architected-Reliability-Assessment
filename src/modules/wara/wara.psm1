Function Start-WAFCollector {
    [CmdletBinding()]
    Param(
        [switch]$Debugging,
        [switch]$SAP,
        [switch]$AVD,
        [switch]$AVS,
        [switch]$HPC,
        [ValidatePattern('^(\/subscriptions\/)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [String[]]$SubscriptionIds,
        [ValidatePattern('^\/subscriptions\/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\/resourceGroups\/[a-zA-Z0-9._-]+$')]
        [String[]]$ResourceGroups,
        [GUID]$TenantID,
        [ValidatePattern('^[^<>&%\\?/]+=~[^<>&%\\?/]+$|[^<>&%\\?/]+!~[^<>&%\\?/]+$')]
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


    if ($ConfigFile) {
        $ConfigData = Import-WAFConfigFileData -ConfigFile $ConfigFile
    }

    #Use Null Coalescing to set the values of parameters.
    $Scope_TenantId = $TenantID ?? $ConfigData.TenantId
    $Scope_SubscriptionIds = $SubscriptionIds ?? $ConfigData.SubscriptionIds ?? @()
    $Scope_ResourceGroups = $ResourceGroups ?? $ConfigData.ResourceGroups ?? @()
    #$Scope_Tags = $Tags ?? $ConfigData.Tags

    #Import Recommendation Object from APRL
    $RecommendationObject = Invoke-RestMethod "https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/data/recommendations.json"

    #TODO: Test if the parameters are valid

    #Connect to Azure
    Connect-WAFAzure -TenantId $Scope_TenantId -AzureEnvironment $AzureEnvironment

    #Get Implicit Subscription Ids from Scope
    $Scope_ImplicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
        
    #Get all resources from the implicit subscription ids
    #$UnfilteredResources = Get-WAFUnfilteredResourceList -SubscriptionIds $ImplicitSubscriptionIds

    $Recommendations = Invoke-WAFQueryLoop -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '') -RecommendationObject $RecommendationObject
        
    $impactedResourceObj = $Recommendations.ForEach({ [impactedResourceObj]::new($_) })

    $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups

    $advisorResourceObj = Get-WAFAdvisorRecommendations -Subid $Scope_ImplicitSubscriptionIds.replace("/subscriptions/", '') -HighAvailability

    $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups



    $outputJson = [PSCustomObject]@{
        impactedResources = $impactedResourceObj
        advisory = $advisorResourceObj
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
