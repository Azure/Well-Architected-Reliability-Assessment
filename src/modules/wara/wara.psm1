function Start-WARACollector {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Specialized')]
        [Parameter(ParameterSetName = 'ConfigFileSet')]
        [switch] $SAP,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Specialized')]
        [Parameter(ParameterSetName = 'ConfigFileSet')]
        [switch] $AVD,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Specialized')]
        [Parameter(ParameterSetName = 'ConfigFileSet')]
        [switch] $AVS,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Specialized')]
        [Parameter(ParameterSetName = 'ConfigFileSet')]
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

        [Parameter(ParameterSetName = 'Default')]
        [ValidatePattern('^https:\/\/.+$')]
        [string] $RecommendationResourceTypesUri = 'https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/WARAinScopeResTypes.csv',

        # Runbook parameters...
        [Parameter(ParameterSetName = 'Default')]
        [switch] $UseImplicitRunbookSelectors,

        [Parameter(ParameterSetName = 'Default')]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string] $RunbookFile
    )

    Write-Debug 'Debugging mode is enabled'
    Write-Progress -Activity 'WARA Collector' -Status 'Starting WARA Collector' -PercentComplete 0 -Id 1

    # Determine which parameter set is active
    switch ($PSCmdlet.ParameterSetName) {
        'ConfigFileSet' {
            Write-Debug 'Using ConfigFileSet parameter set'
            Write-Debug "ConfigFile: $ConfigFile"
            Write-Debug 'Importing ConfigFile data'
            $ConfigData = Import-WAFConfigFileData -ConfigFile $ConfigFile
            Write-Debug 'Testing TenantId, SubscriptionIds, ResourceGroups, and Tags'
            $ConfigData.TenantId = ([guid][string]$ConfigData.TenantId).Guid
            $null = Test-WAFIsGuid -StringGuid $ConfigData.TenantId
            $null = if ($ConfigData.SubscriptionIds) { Test-WAFSubscriptionId -InputValue $ConfigData.SubscriptionIds }
            $null = if ($ConfigData.ResourceGroups) { Test-WAFResourceGroupId -InputValue $ConfigData.ResourceGroups }
            $null = if ($ConfigData.Tags) { Test-WAFTagPattern -InputValue $ConfigData.Tags }
        }
        'Default' {
            Write-Debug 'Using Default parameter set'

            Write-Debug "Parameter set values: $($PSBoundParameters.Keys)"

            if ($PSBoundParameters.keys.contains( 'SubscriptionIds') -or $PSBoundParameters.keys.contains('ResourceGroups')) {
                Write-Debug "We contain the parameters."
            }
            else {
                Write-Debug "We do not contain the parameters."
                throw "The parameter SubscriptionIds or ResourceGroups is required when using the Default parameter set."
            }
        }
    }

    #Use Null Coalescing to set the values of parameters.
    Write-Progress -Activity 'WARA Collector' -Status 'Setting Scope' -PercentComplete 1 -Id 1
    $Scope_TenantId = $ConfigData.TenantId ?? $TenantID ?? (throw 'Tenant ID is required.')
    $Scope_SubscriptionIds = $ConfigData.SubscriptionIds ?? $SubscriptionIds ?? @()
    $Scope_ResourceGroups = $ConfigData.ResourceGroups ?? $ResourceGroups ?? @()
    $Scope_Tags = $ConfigData.Tags ?? $Tags ?? @()

    Write-Progress -Activity 'WARA Collector' -Status 'Setting Scope' -PercentComplete 3 -Id 1
    $Scope_SubscriptionIds = Repair-WAFSubscriptionId -SubscriptionIds $Scope_SubscriptionIds

    Write-Debug "Tenant ID: $Scope_TenantId"
    Write-Debug "Subscription IDs: $Scope_SubscriptionIds"
    Write-Debug "Resource Groups: $Scope_ResourceGroups"
    Write-Debug "Tags: $Scope_Tags"

    if ($SAP) {
        Write-Debug 'SAP switch is enabled'
        $SpecializedWorkloads += "specialized.workload/sap"
    }
    if ($AVD) {
        Write-Debug 'AVD switch is enabled'
        $SpecializedWorkloads += "specialized.workload/avd"
    }
    if ($AVS) {
        Write-Debug 'AVS switch is enabled'
        $SpecializedWorkloads += "specialized.workload/avs"
    }
    if ($HPC) {
        Write-Debug 'HPC switch is enabled'
        $SpecializedWorkloads += "specialized.workload/hpc"
    }

    if ($SpecializedWorkloads) {
        Write-Debug "Specialized Workloads: $SpecializedWorkloads"
    }


    #Import Recommendation Object from APRL
    Write-Progress -Activity 'WARA Collector' -Status 'Importing APRL Recommendation Object from GitHub' -PercentComplete 5 -Id 1
    Write-Debug 'Importing APRL Recommendation Object from GitHub'
    $RecommendationObject = Invoke-RestMethod $RecommendationDataUri
    Write-Debug "Count of APRL Recommendation Object: $($RecommendationObject.count)"
    
    
    #Create Recommendation Object HashTable for faster lookup
    Write-Debug 'Creating Recommendation Object HashTable for faster lookup'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating Recommendation Object HashTable' -PercentComplete 8 -Id 1
    $RecommendationObjectHash = @{}
    $RecommendationObject.ForEach({ $RecommendationObjectHash[$_.aprlGuid] = $_ })
    Write-Debug "Count of Recommendation Object Hashtable: $($RecommendationObjectHash.count)"


    #Import WARA InScope Resource Types CSV from APRL
    Write-Debug 'Importing WARA InScope Resource Types CSV from GitHub'
    Write-Progress -Activity 'WARA Collector' -Status 'Importing WARA InScope Resource Types CSV' -PercentComplete 11 -Id 1
    $RecommendationResourceTypes = Invoke-RestMethod $RecommendationResourceTypesUri | ConvertFrom-Csv | Where-Object { $_.WARAinScope -eq 'yes' }
    Write-Debug "Count of WARA InScope Resource Types: $($RecommendationResourceTypes.count)"
    
    
    #Add Specialized Workloads to WARA InScope Resource Types
    Write-Debug 'Adding Specialized Workloads to WARA InScope Resource Types'
    Write-Progress -Activity 'WARA Collector' -Status 'Adding Specialized Workloads to WARA InScope Resource Types' -PercentComplete 14 -Id 1
    $RecommendationResourceTypes += $SpecializedWorkloads
    Write-Debug "Count of WARA InScope Resource Types with Specialized Workloads: $($RecommendationResourceTypes.count)"
    

    #Create TypesNotInAPRLOrAdvisor Object from WARA InScope Resource Types
    Write-Debug 'Creating TypesNotInAPRLOrAdvisor Object from WARA InScope Resource Types'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating TypesNotInAPRLOrAdvisor Object' -PercentComplete 17 -Id 1
    $TypesNotInAPRLOrAdvisor = ($RecommendationResourceTypes | Where-Object { $_.InAprlAndOrAdvisor -eq "No" }).ResourceType
    Write-Debug "Count of TypesNotInAPRLOrAdvisor: $($TypesNotInAPRLOrAdvisor.count)"


    #Connect to Azure
    Write-Debug 'Connecting to Azure if not connected.'
    Write-Progress -Activity 'WARA Collector' -Status 'Connecting to Azure' -PercentComplete 20 -Id 1
    Connect-WAFAzure -TenantId $Scope_TenantId -AzureEnvironment $AzureEnvironment


    #Get Implicit Subscription Ids from Scope
    Write-Debug 'Getting Implicit Subscription Ids from Scope'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Implicit Subscription Ids' -PercentComplete 23 -Id 1
    $Scope_ImplicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Implicit Subscription Ids: $Scope_ImplicitSubscriptionIds"


    #Get all resources from the Implicit Subscription ID scope - We use this later to add type, location, subscriptionid, resourcegroup to the impactedResourceObj objects
    Write-Debug 'Getting all resources from the Implicit Subscription ID scope'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting All Resources' -PercentComplete 26 -Id 1
    $AllResources = Invoke-WAFQuery -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')
    Write-Debug "Count of Resources: $($AllResources.count)"


    #Create HashTable of all resources for faster lookup
    Write-Debug 'Creating HashTable of all resources for faster lookup'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating All Resources HashTable' -PercentComplete 29 -Id 1
    $AllResourcesHash = @{}
    $AllResources.ForEach({ $AllResourcesHash[$_.id] = $_ })
    Write-Debug "All Resources Hash: $($AllResourcesHash.count)"


    #Filter all resources by subscription, resourcegroup, and resource scope
    Write-Debug 'Filtering all resources by subscription, resourcegroup, and resource scope'
    Write-Progress -Activity 'WARA Collector' -Status 'Filtering All Resources' -PercentComplete 32 -Id 1
    $Scope_AllResources = Get-WAFFilteredResourceList -UnfilteredResources $AllResources -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of filtered Resources: $($Scope_AllResources.count)"


    #Filter all resources by InScope Resource Types - We do this because we need to be able to compare resource ids to generate the generic recommendations(Resource types that have no recommendations or are not in advisor but also need to be validated)
    Write-Debug 'Filtering all resources by WARA InScope Resource Types'
    Write-Progress -Activity 'WARA Collector' -Status 'Filtering All Resources by WARA InScope Resource Types' -PercentComplete 35 -Id 1
    $Scope_AllResources = Get-WAFResourcesByList -ObjectList $Scope_AllResources -FilterList $RecommendationResourceTypes.ResourceType -KeyColumn 'type'
    Write-Debug "Count of filtered by type Resources: $($Scope_AllResources.count)"



    #Get all APRL recommendations from the Implicit Subscription ID scope
    Write-Debug 'Getting all APRL recommendations from the Implicit Subscription ID scope'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting APRL Recommendations' -PercentComplete 38 -Id 1
    $Recommendations = Invoke-WAFQueryLoop -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '') -RecommendationObject $RecommendationObject -AddedTypes $SpecializedWorkloads -ProgressId 2
    Write-Debug "Count of Recommendations: $($Recommendations.count)"


    #Filter resource recommendation objects by subscription, resourcegroup, and resource scope
    Write-Debug 'Filtering APRL recommendation objects by subscription, resourcegroup, and resource scope'
    Write-Progress -Activity 'WARA Collector' -Status 'Filtering APRL Recommendations' -PercentComplete 41 -Id 1
    $Filter_Recommendations = Get-WAFFilteredResourceList -UnfilteredResources $Recommendations -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of APRL recommendation objects: $($Filter_Recommendations.count)"


    #Create impactedResourceObj objects from the recommendations
    Write-Debug 'Creating impactedResourceObj objects from the recommendations'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating Impacted Resource Objects' -PercentComplete 44 -Id 1
    $impactedResourceObj = Build-impactedResourceObj -impactedResource $Filter_Recommendations -allResources $AllResourcesHash -RecommendationObject $RecommendationObjectHash
    Write-Debug "Count of impactedResourceObj objects: $($impactedResourceObj.count)"


    #Create list of validationResourceIds from the impactedResourceObj objects
    Write-Debug 'Creating hashtable of validationResources from the impactedResourceObj objects'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating Validation Resources' -PercentComplete 47 -Id 1
    $validationResources = @{}
    foreach ($obj in $impactedResourceObj | Select-Object id, name, type, location, subscriptionid, resourcegroup, checkname, selector) {
        $key = "$($obj.id)"
        if (-not $validationResources.ContainsKey($key)) {
            $validationResources[$key] = $obj
        }
    }
    Write-Debug "Count of validationResourceIds: $($validationResources.count)"

    #Add In Scope resources to validationResources HashTable
    #By adding the $Scope_AllResources to the validationResources HashTable, we can ensure that we have all resources in the scope that need to be validated.
    #Adding the resources AFTER the first loop ensures that we do not add resources that are already in the impactedResourceObj objects.
    #This means we do not have to worry about overwriting the objects.
    Write-Debug "Add In Scope resources to validationResources HashTable"
    Write-Progress -Activity 'WARA Collector' -Status 'Adding In Scope Resources to Validation Resources' -PercentComplete 50 -Id 1
    foreach ($obj in $Scope_AllResources) {
        $key = "$($obj.id)"
        if (-not $validationResources.ContainsKey($key)) {
            $validationResources[$key] = $obj
        }
    }
    Write-Debug "Count of validationResourceIds: $($validationResources.count)"


    #Create validationResourceObj objects from the impactedResourceObj objects
    Write-Debug 'Creating validationResourceObj objects from the impactedResourceObj objects'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating Validation Resource Objects' -PercentComplete 53 -Id 1
    $validationResourceObj = Build-validationResourceObj -validationResources $validationResources -RecommendationObject $RecommendationObject -TypesNotInAPRLOrAdvisor $TypesNotInAPRLOrAdvisor
    Write-Debug "Count of validationResourceObj objects: $($validationResourceObj.count)"


    #Combine impactedResourceObj and validationResourceObj objects
    Write-Debug 'Combining impactedResourceObj and validationResourceObj objects'
    Write-Progress -Activity 'WARA Collector' -Status 'Combining Impacted and Validation Resource Objects' -PercentComplete 56 -Id 1
    $impactedResourceObj += $validationResourceObj
    Write-Debug "Count of combined validationResourceObj impactedResourceObj objects: $($impactedResourceObj.count)"


    #Get Advisor Metadata to include recommendations that are not in Advisor under 'HighAvailability'
    Write-Debug 'Getting Advisor Metadata'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Advisor Metadata' -PercentComplete 59 -Id 1
    $AdvisorMetadata = Get-WAFAdvisorMetadata
    Write-Debug "Count of Advisor Metadata: $($AdvisorMetadata.count)"

    #Get Other Recommendations
    Write-Debug 'Getting Other Recommendations'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Other Recommendations' -PercentComplete 62 -Id 1
    $OtherRecommendations = Get-WARAOtherRecommendations -RecommendationObject $RecommendationObject -AdvisorMetadata $AdvisorMetadata
    Write-Debug "Count of Other Recommendations: $($OtherRecommendations.count)"


    #Get Advisor Recommendations
    Write-Debug 'Getting Advisor Recommendations'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Advisor Recommendations' -PercentComplete 65 -Id 1
    $advisorResourceObj = Get-WAFAdvisorRecommendation -AdditionalRecommendationIds $OtherRecommendations -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '') -HighAvailability
    Write-Debug "Count of Advisor Recommendations: $($advisorResourceObj.count)"

    #Prior to filtering, capture all "global" recommendations that are microsoft.subscriptions/subscriptions since these get filtered out.
    Write-Debug 'Capturing global recommendations that are microsoft.subscriptions/subscriptions'
    Write-Progress -Activity 'WARA Collector' -Status 'Capturing Global Recommendations' -PercentComplete 68 -Id 1
    $globalRecommendations = $advisorResourceObj | Where-Object { $_.type -eq 'microsoft.subscriptions/subscriptions' }
    Write-Debug "Count of global recommendations: $($globalRecommendations.count)"


    #Filter Advisor Recommendations by subscription, resource group, and resource scope
    Write-Debug 'Filtering Advisor Recommendations by subscription, resource group, and resource scope'
    Write-Progress -Activity 'WARA Collector' -Status 'Filtering Advisor Recommendations' -PercentComplete 71 -Id 1
    $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -SubscriptionFilters $Scope_SubscriptionIds -ResourceGroupFilters $Scope_ResourceGroups
    Write-Debug "Count of filtered Advisor Recommendations: $($advisorResourceObj.count)"


    #If we passed tags, filter impactedResourceObj and advisorResourceObj by tagged resource group and tagged resource scope
    if (![string]::IsNullOrEmpty($Scope_Tags)) {

        Write-Debug 'Starting Tag Filtering'
        Write-Progress -Activity 'WARA Collector' -Status 'Starting Tag Filtering' -PercentComplete 72 -Id 1
        Write-Debug "Scope Tags: $Scope_Tags"


        #Get all tagged resource groups from the Implicit Subscription ID scope
        Write-Debug 'Getting all tagged resource groups from the Implicit Subscription ID scope'
        Write-Progress -Activity 'WARA Collector' -Status 'Getting Tagged Resource Groups' -PercentComplete 72 -Id 1
        $Filter_TaggedResourceGroupIds = Get-WAFTaggedResourceGroup -TagArray $Scope_Tags -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')
        Write-Debug "Count of Tagged Resource Group Ids: $($Filter_TaggedResourceGroupIds.count)"


        #Get all tagged resources from the Implicit Subscription ID scope
        Write-Debug 'Getting all tagged resources from the Implicit Subscription ID scope'
        Write-Progress -Activity 'WARA Collector' -Status 'Getting Tagged Resources' -PercentComplete 73 -Id 1
        $Filter_TaggedResourceIds = Get-WAFTaggedResource -TagArray $Scope_Tags -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')
        Write-Debug "Count of Tagged Resource Ids: $($Filter_TaggedResourceIds.count)"


        #Filter impactedResourceObj objects by tagged resource group and resource scope
        Write-Debug 'Filtering impactedResourceObj objects by tagged resource group and resource scope'
        Write-Progress -Activity 'WARA Collector' -Status 'Filtering Impacted Resource Objects' -PercentComplete 73 -Id 1
        $impactedResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $impactedResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds
        Write-Debug "Count of tag filtered impactedResourceObj objects: $($impactedResourceObj.count)"


        #Filter Advisor Recommendations by tagged resource group and resource scope
        Write-Debug 'Filtering Advisor Recommendations by tagged resource group and resource scope'
        Write-Progress -Activity 'WARA Collector' -Status 'Filtering Advisor Recommendations' -PercentComplete 73 -Id 1
        $advisorResourceObj = Get-WAFFilteredResourceList -UnfilteredResources $advisorResourceObj -ResourceGroupFilters $Filter_TaggedResourceGroupIds -ResourceFilters $Filter_TaggedResourceIds
        Write-Debug "Count of tag filtered Advisor Recommendations: $($advisorResourceObj.count)"
    }

    #Build Specialized Resource Object if Specialized Workloads are selected but not present in the impactedResourceObj.
    #Some of the specialized workloads have queries that run. If this is the case then we need to check if the impactedResourceObj contains these resource types and if not add them to the impactedResourceObj.
    if ($SpecializedWorkloads) {
        Write-Debug 'Building Specialized Resource Object'
        
        Write-Progress -Activity 'WARA Collector' -Status 'Building Specialized Resource Object' -PercentComplete 74 -Id 1
        $specializedResourceObj = build-specializedResourceObj -SpecializedResourceObj $SpecializedWorkloads -recommendationObject $RecommendationObject
        Write-Debug "Count of Specialized Resource Object: $($specializedResourceObj.count)"
        
        Write-Debug 'Adding Specialized Resource Object to impactedResourceObj'
        $impactedResourceObj += $specializedResourceObj
        Write-Debug "Count of impactedResourceObj with Specialized Resource Object: $($impactedResourceObj.count)"
    }

    #Add global recommendations back to advisorResourceObj
    Write-Debug 'Adding global recommendations back to advisorResourceObj'
    Write-Progress -Activity 'WARA Collector' -Status 'Adding Global Recommendations' -PercentComplete 75 -Id 1
    $advisorResourceObj += $globalRecommendations
    Write-Debug "Count of advisorResourceObj with global recommendations: $($advisorResourceObj.count)"

    #Build Resource Type Object
    Write-Debug 'Building Resource Type Object with impactedResourceObj and advisorResourceObj'
    Write-Progress -Activity 'WARA Collector' -Status 'Building Resource Type Object' -PercentComplete 78 -Id 1
    $resourceTypeObj = Build-resourceTypeObj -resourceObj $($impactedResourceObj + $advisorResourceObj) -TypesNotInAPRLOrAdvisor $TypesNotInAPRLOrAdvisor
    Write-Debug "Count of Resource Type Object : $($resourceTypeObj.count)"

    #Get Azure Outages
    Write-Debug 'Getting Azure Outages'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Azure Outages' -PercentComplete 81 -Id 1
    $outageResourceObj = Get-WAFOutage -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')


    #Get Azure Retirements
    Write-Debug 'Getting Azure Retirements'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Azure Retirements' -PercentComplete 84 -Id 1
    $retirementResourceObj = Get-WAFResourceRetirement -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')


    #Get Azure Support Tickets
    Write-Debug 'Getting Azure Support Tickets'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Azure Support Tickets' -PercentComplete 87 -Id 1
    $supportTicketObjects = Get-WAFSupportTicket -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')


    #Get Azure Service Health
    Write-Debug 'Getting Azure Service Health'
    Write-Progress -Activity 'WARA Collector' -Status 'Getting Azure Service Health' -PercentComplete 90 -Id 1
    $serviceHealthObjects = Get-WAFServiceHealth -SubscriptionIds $Scope_ImplicitSubscriptionIds.replace('/subscriptions/', '')


    #Create output JSON
    Write-Debug 'Creating output JSON'
    Write-Progress -Activity 'WARA Collector' -Status 'Creating Output JSON' -PercentComplete 93 -Id 1
    $outputJson = [PSCustomObject]@{
        impactedResources = $impactedResourceObj
        resourceType      = $resourceTypeObj
        advisory          = $advisorResourceObj
        outages           = $outageResourceObj
        retirements       = $retirementResourceObj
        supportTickets    = $supportTicketObjects
        serviceHealth     = $serviceHealthObjects
    }

    Write-Debug 'Output JSON'
    Write-Progress -Activity 'WARA Collector' -Status 'Output JSON' -PercentComplete 100 -Id 1 -Completed
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
        [hashtable] $RecommendationObject
    )


    $impactedResourceObj = [impactedResourceFactory]::new($impactedResources, $allResources, $RecommendationObject)
    $r = $impactedResourceObj.createImpactedResourceObjects()

    return $r
}


Function Build-validationResourceObj {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable] $validationResources,

        [Parameter(Mandatory = $true)]
        [PSObject] $RecommendationObject,

        [Parameter(Mandatory = $true)]
        [PSObject] $TypesNotInAPRLOrAdvisor
    )

    $validatorObj = [validationResourceFactory]::new($RecommendationObject, $validationResources, $TypesNotInAPRLOrAdvisor)
    $r = $validatorObj.createValidationResourceObjects()

    return $r
}

Function Build-resourceTypeObj {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject] $ResourceObj,

        [Parameter(Mandatory = $true)]
        [PSObject] $TypesNotInAPRLOrAdvisor
    )

    $return = [resourceTypeFactory]::new($ResourceObj, $TypesNotInAPRLOrAdvisor).createResourceTypeObjects()

    return $return
}

function build-specializedResourceObj {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject] $SpecializedResourceObj,

        [Parameter(Mandatory = $true)]
        [PSObject] $recommendationObject
    )

    $return = [specializedResourceFactory]::new($SpecializedResourceObj,$recommendationObject).createSpecializedResourceObjects()

    return $return
}

Function Get-WARAOtherRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject] $RecommendationObject,

        [Parameter(Mandatory = $true)]
        [PSObject] $AdvisorMetadata
    )

    $metadata = $AdvisorMetadata.where({ $_.recommendationCategory -ne 'HighAvailability' }).id

    #Returns recommendations that are in APRL but not in Advisor under 'HighAvailability'
    $return = $RecommendationObject.recommendationTypeId | Where-Object { $_ -in $metadata }

    return $return
}

class aprlResourceTypeObj {
    [string] ${Resource Type}
    [int] ${Number Of Resources}
    [string] ${Available in APRL/ADVISOR?}
    [string] ${Assessment Owner}
    [string] $Status
    [string] $Notes
}

class resourceTypeFactory {
    [PSObject]$impactedResourceObj
    [PSObject]$TypesNotInAPRLOrAdvisor

    resourceTypeFactory([PSObject]$impactedResourceObj, [PSObject]$TypesNotInAPRLOrAdvisor) {
        $this.impactedResourceObj = $impactedResourceObj | Group-Object Type | Select-Object Name, Count
        $this.TypesNotInAPRLOrAdvisor = $TypesNotInAPRLOrAdvisor
    }

    [object[]] createResourceTypeObjects() {
        $return = foreach ($type in $this.impactedResourceObj) {
            $r = [aprlResourceTypeObj]::new()
            $r.'Resource Type' = $type.Name
            $r.'Number Of Resources' = $type.Count
            $r.'Available in APRL/ADVISOR?' = $(($this.TypesNotInAPRLOrAdvisor -contains $type.Name) ? "No" : "Yes")
            $r.'Assessment Owner' = "APRL"
            $r.Status = "Active"
            $r.notes = ""

            $r
        }
        return $return
    }
}

class aprlResourceObj {
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

class impactedResourceFactory {
    [PSObject] $impactedResources
    [hashtable] $allResources
    [hashtable] $RecommendationObject

    impactedResourceFactory([PSObject]$impactedResources, [hashtable]$allResources, [hashtable]$RecommendationObject) {
        $this.impactedResources = $impactedResources
        $this.allResources = $allResources
        $this.RecommendationObject = $RecommendationObject
    }

    [object[]] createImpactedResourceObjects() {
        $return = foreach ($impactedResource in $this.impactedResources) {
            $r = [aprlResourceObj]::new()
            $r.validationAction = "APRL - Queries"
            $r.RecommendationId = $impactedResource.recommendationId
            $r.Name = $impactedResource.name
            $r.Id = $impactedResource.id
            $r.type = $this.RecommendationObject[$r.recommendationId].recommendationResourceType ?? $this.allResources[$r.id].type ?? "Unknown"
            $r.location = $this.allResources[$r.id].location ?? "Unknown"
            $r.subscriptionId = $this.allResources[$r.id].subscriptionId ?? $r.id.split("/")[2] ?? "Unknown"
            $r.resourceGroup = $this.allResources[$r.id].resourceGroup ?? $r.id.split("/")[4] ?? "Unknown"
            $r.Param1 = $impactedResource.param1
            $r.Param2 = $impactedResource.param2
            $r.Param3 = $impactedResource.param3
            $r.Param4 = $impactedResource.param4
            $r.Param5 = $impactedResource.param5
            $r.checkName = $impactedResource.checkName
            $r.selector = $impactedResource.selector ?? "APRL"
            $r
        }
        return $return
    }
}



class validationResourceFactory {
    # This class is used to create validationResourceObj objects
    
    # Properties
    [PSObject] $recommendationObject # The recommendation object
    [hashtable] $validationResources # The validation resources
    [PSObject] $TypesNotInAPRLOrAdvisor # Resource types that we want to create a recommendation for but do not have a recommendation for

    validationResourceFactory([PSObject]$recommendationObject, [hashtable]$validationResources, [PSObject]$TypesNotInAPRLOrAdvisor) {
        $this.recommendationObject = $recommendationObject
        $this.validationResources = $validationResources
        $this.TypesNotInAPRLOrAdvisor = $TypesNotInAPRLOrAdvisor
    }

    [object[]] createValidationResourceObjects() {
        $return = @()

        $return = foreach ($v in $this.validationResources.GetEnumerator()) {

            $impactedResource = $v.value

            $recommendationByType = $this.recommendationObject.where({ $_.automationAvailable -eq $false -and $impactedResource.type -eq $_.recommendationResourceType -and $_.recommendationMetadataState -eq "Active" -and [string]::IsNullOrEmpty($_.recommendationTypeId) })


            if ($null -ne $recommendationByType) {
                foreach ($rec in $recommendationByType) {
                    $r = [aprlResourceObj]::new()
                    $r.validationAction = [validationResourceFactory]::getValidationAction($rec.query)
                    $r.recommendationId = $rec.aprlGuid
                    $r.name = $impactedResource.name
                    $r.id = $impactedResource.id
                    $r.type = $impactedResource.type
                    $r.location = $impactedResource.location
                    $r.subscriptionId = $impactedResource.subscriptionId
                    $r.resourceGroup = $impactedResource.resourceGroup
                    $r.param1 = ''
                    $r.param2 = ''
                    $r.param3 = ''
                    $r.param4 = ''
                    $r.param5 = ''
                    $r.checkName = ''
                    $r.selector = $impactedResource.selector ?? "APRL"
                    $r
                }
            }
            elseif ($impactedResource.type -in $this.TypesNotInAPRLOrAdvisor) {
                $r = [aprlResourceObj]::new()
                $r.validationAction = [validationResourceFactory]::getValidationAction("No Recommendations")
                $r.recommendationId = ''
                $r.name = $impactedResource.name
                $r.id = $impactedResource.id
                $r.type = $impactedResource.type
                $r.location = $impactedResource.location
                $r.subscriptionId = $impactedResource.subscriptionId
                $r.resourceGroup = $impactedResource.resourceGroup
                $r.param1 = ''
                $r.param2 = ''
                $r.param3 = ''
                $r.param4 = ''
                $r.param5 = ''
                $r.checkName = ''
                $r.selector = $impactedResource.selector ?? "APRL"
                $r
            }
            else {
                Write-Error "No recommendation found for $($impactedResource.type) with resource id $($impactedResource.id)"
            }
        }
            
        
        return $return
    }

    static [string] getValidationAction($query) {
        $return = switch -wildcard ($query) {
            "*development*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "*cannot-be-validated-with-arg*" { 'IMPORTANT - Recommendation cannot be validated with ARGs - Validate Resources manually' }
            "*Azure Resource Graph*" { 'IMPORTANT - This resource has a query but the automation is not available - Validate Resources manually' }
            "No Recommendations" { 'IMPORTANT - Resource Type is not available in either APRL or Advisor - Validate Resources manually if applicable, if not delete this line' }
            default { "IMPORTANT - Query does not exist - Validate Resources Manually" }
        }
        return $return
    }
}

class specializedResourceFactory {
    # This class is used to create specializedResourceObj objects
    
    # Properties
    [PSObject] $specializedResources # The specialized resources
    [PSObject] $RecommendationObject # The recommendation object

    specializedResourceFactory([PSObject]$specializedResources, [PSObject]$RecommendationObject) {
        $this.specializedResources = $specializedResources
        $this.RecommendationObject = $RecommendationObject
    }

    [object[]] createSpecializedResourceObjects() {
        $return = foreach ($s in $this.specializedResources) {

            $thisType = $this.RecommendationObject.where({ $_.recommendationResourceType -eq $s})
            foreach ($type in $thisType){
                $r = [aprlResourceObj]::new()
                $r.validationAction = [specializedResourceFactory]::getValidationAction($type.query)
                $r.recommendationId = $type.aprlGuid
                $r.name = ''
                $r.id = ''
                $r.type = $s
                $r.location = ''
                $r.subscriptionId = ''
                $r.resourceGroup = ''
                $r.param1 = ''
                $r.param2 = ''
                $r.param3 = ''
                $r.param4 = ''
                $r.param5 = ''
                $r.checkName = ''
                $r.selector = "APRL"
                $r
            }
      
        }
        return $return
    }

    static [string] getValidationAction($query) {
        $return = switch -wildcard ($query) {
            "*development*" { 'IMPORTANT - Query under development - Validate Resources manually' }
            "*cannot-be-validated-with-arg*" { 'IMPORTANT - Recommendation cannot be validated with ARGs - Validate Resources manually' }
            "*Azure Resource Graph*" { 'IMPORTANT - This resource has a query but the automation is not available - Validate Resources manually' }
            "No Recommendations" { 'IMPORTANT - Resource Type is not available in either APRL or Advisor - Validate Resources manually if applicable, if not delete this line' }
            default { "IMPORTANT - Query does not exist - Validate Resources Manually" }
        }
        return $return
    }
}

