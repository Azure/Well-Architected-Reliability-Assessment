BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/wara.psd1"
    Import-Module -Name $modulePath -Force
}

Describe 'Start-WARACollector Parameter Sets' {
    BeforeAll {

        Mock Start-WARACollector { return $null } -Verifiable -RemoveParameterValidation "TenantID", "SubscriptionIds", "ConfigFile", "ResourceGroups"
    }
    Context 'ConfigFile' {
        It 'Should proceed when used alone.' {
            $result = Start-WARACollector -ConfigFile "$PSScriptRoot/../data/wara/test_configfiledata.txt"
            Assert-MockCalled Start-WARACollector -Exactly 1 -Scope It
        }
    }
    Context 'ConfigFile + Specialized' {
        It 'Should proceed with ConfigFile + Specialized.' {
            $result = Start-WARACollector -ConfigFile "$PSScriptRoot/../data/wara/test_configfiledata.txt" -SAP -AVS -AVD -HPC -AI_GPT_RAG -ORACLE
            Assert-MockCalled Start-WARACollector -Exactly 1 -Scope It
        }
    }
    Context 'TenantId + SubscriptionIds' {
        It 'Should proceed with TenantId + SubscriptionIds' {
            $result = Start-WARACollector -TenantID $(New-Guid).Guid -SubscriptionIds '/subscriptions/11111111-1111-1111-111111111111'
            Assert-MockCalled Start-WARACollector -Exactly 1 -Scope It
        }
    }
    Context 'TenantId + SubscriptionIds + ResourceGroups' {
        It 'Should proceed with TenantId + SubscriptionIds + ResourceGroups' {
            $result = Start-WARACollector -TenantID $(New-Guid).Guid -SubscriptionIds '/subscriptions/11111111-1111-1111-111111111111' -ResourceGroups 'RG1'
            Assert-MockCalled Start-WARACollector -Exactly 1 -Scope It
        }
    }
    Context 'TenantId + SubscriptionIds + ResourceGroups + Specialized' {
        It 'Should proceed with TenantId + SubscriptionIds + ResourceGroups + Specialized' {
            $result = Start-WARACollector -TenantID $(New-Guid).Guid -SubscriptionIds '/subscriptions/11111111-1111-1111-111111111111' -ResourceGroups 'RG1' -SAP -AVS -AVD -HPC -AI_GPT_RAG -ORACLE
            Assert-MockCalled Start-WARACollector -Exactly 1 -Scope It
        }
    }
}

Describe 'Start-WARACollector' {
    Context 'When given the Default parameter set without SubscriptionIds and ResourceGroups' {
        It 'Should throw an exception with the specified message' {
            $scriptBlock = { Start-WARACollector -TenantID $(new-guid).guid }
            $scriptBlock | Should -Throw
        }
    }
    Context 'Default Parameter Set' {
        It 'Should throw an exception when TenantID is invalid GUID' {
            $scriptBlock = { Start-WARACollector -TenantID 'invalid-guid' -SubscriptionIds '/subscriptions/11111111-1111-1111-111111111111' }
            $scriptBlock | Should -Throw
        }

        It 'Should throw an exception when SubscriptionIds are invalid' {
            $scriptBlock = { Start-WARACollector -TenantID $(New-Guid).Guid -SubscriptionIds 'invalid-subscription-id' }
            $scriptBlock | Should -Throw
        }

    }
    Context 'ConfigFileSet Parameter Set' {
        It 'Should throw an exception when ConfigFile does not exist' {
            $scriptBlock = { Start-WARACollector -TenantID $(new-guid).guid -ConfigFile 'C:\invalid\path\config.json' }
            $scriptBlock | Should -Throw
        }
    }
    Context 'Different Parameter Sets' {
        It 'Should throw an exception when parameters from both sets are provided' {
            $scriptBlock = { Start-WARACollector -TenantID $(new-guid).guid -ConfigFile 'C:\invalid\path\config.json' -SubscriptionIds '/subscriptions/11111111-1111-1111-111111111111' }
            $scriptBlock | Should -Throw
        }
    }
    Context 'When given correct parameters with -passthru' {
        BeforeAll {
            $AllResources_TestData = get-content "$PSScriptRoot/../data/wara/test_allresourcesdata.json" -raw | ConvertFrom-Json -depth 20
            $QueryLoop_TestData = get-content "$PSScriptRoot/../data/wara/test_queryloopdata.json" -raw | ConvertFrom-Json -depth 20
            $AdvisorMeta_TestData = get-content "$PSScriptRoot/../data/wara/test_advisormetadata.json" -raw | ConvertFrom-Json -depth 20
            $RecommendationObject_TestData = get-content "$PSScriptRoot/../data/wara/test_recommendationobjectdata.json" -raw | ConvertFrom-Json -depth 20
            $RecommendationResourceTypes_TestData = get-content "$PSScriptRoot/../data/wara/test_recommendationresourcetypesdata.csv" -Raw
            $Advisor_TestData = get-content "$PSScriptRoot/../data/wara/test_advisordata.json" -raw | ConvertFrom-Json -depth 20
            $TaggedResourceGroup_TestData = @("/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-B1")
            $TaggedResource_TestData = @("/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-A1/providers/Microsoft.ApiManagement/service/apiService1")
            $Outage_TestData = get-content "$PSScriptRoot/../data/outage/restApiMultipleResponseData.json" -raw | ConvertFrom-Json -depth 20 | Select-Object Name, Properties
            $Retirement_TestData = get-content "$PSScriptRoot/../data/wara/test_retirementdata.json" -raw | ConvertFrom-Json -depth 20
            $SupportTicket_TestData = get-content "$PSScriptRoot/../data/wara/test_supportticketdata.json" -raw | ConvertFrom-Json -depth 20
            $ServiceHealth_TestData = get-content "$PSScriptRoot/../data/wara/test_servicehealthdata.json" -raw | ConvertFrom-Json -depth 20

            Mock Connect-WAFAzure { write-host "Mocked Connect-WAFAzure" } -ModuleName 'wara'

            Mock Invoke-WAFQuery { return $AllResources_TestData } -ModuleName 'wara'

            Mock Invoke-WAFQueryLoop { return $QueryLoop_TestData } -ModuleName 'wara'

            Mock Get-WAFAdvisorMetadata { return $AdvisorMeta_TestData } -ModuleName 'wara'

            Mock Invoke-RestMethod { return $RecommendationObject_TestData } -ParameterFilter { $uri -eq 'https://azure.github.io/WARA-Build/objects/recommendations.json' } -ModuleName 'wara'

            Mock Invoke-RestMethod { return $RecommendationResourceTypes_TestData } -ParameterFilter { $uri -eq 'https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/WARAinScopeResTypes.csv' } -ModuleName 'wara'

            Mock Get-WARAOtherRecommendations { return $null } -ModuleName 'wara'

            Mock Get-WAFAdvisorRecommendation {

                $AdvData = InModuleScope 'advisor' -Parameters @{
                        Advisor_TestData = $Advisor_TestData
                    } {
                        Build-WAFAdvisorObject -AdvQueryResult $Advisor_TestData
                    }
                return $AdvData
            } -ModuleName 'wara'


            Mock Get-WAFTaggedResourceGroup { return $TaggedResourceGroup_TestData } -ModuleName 'wara'

            Mock Get-WAFTaggedResource { return $TaggedResource_TestData } -ModuleName 'wara'

            Mock Get-WAFOldOutage { return $Outage_TestData } -ModuleName 'wara'

            Mock Get-WAFResourceRetirement { return $Retirement_TestData } -ModuleName 'wara'

            Mock Get-WAFSupportTicket { return $SupportTicket_TestData } -ModuleName 'wara'

            Mock Get-WAFServiceHealth { return $ServiceHealth_TestData } -ModuleName 'wara'

        }
        It 'Should run and return an object that can be measured' {
            $tenantId = $(New-Guid).Guid
            $test_subscriptionIds = "11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222"
            $scriptBlock = Start-WARACollector -TenantID $tenantId -SubscriptionIds $test_subscriptionIds -Debug -PassThru

            # Validate the output of impacted resources
            $scriptblock.impactedresources.count | Should -BeExactly 51

            # Validate the output of impacted resources by type
            $scriptblock.impactedresources.where({ $_.type -eq "Microsoft.ApiManagement/service" }).count | Should -BeExactly 19
            $scriptblock.impactedresources.where({ $_.type -eq "Microsoft.ContainerService/managedClusters" }).count | Should -BeExactly 28
            $scriptblock.impactedresources.where({ $_.type -eq "Microsoft.Network/vpnSites" }).count | Should -BeExactly 4

            # Validate the output of impacted resources by validationAction
            $scriptblock.impactedresources.where({ $_.validationAction -eq "APRL - Queries" }).count | Should -BeExactly 7
            $scriptblock.impactedresources.where({ $_.validationAction -eq "IMPORTANT - Query under development - Validate Resources manually" }).count | Should -BeExactly 4
            $scriptblock.impactedresources.where({ $_.validationAction -eq "IMPORTANT - Recommendation cannot be validated with ARGs - Validate Resources manually" }).count | Should -BeExactly 36
            $scriptblock.impactedresources.where({ $_.validationAction -eq "IMPORTANT - Resource Type is not available in either APRL or Advisor - Validate Resources manually if applicable, if not delete this line" }).count | Should -BeExactly 4

            # Validate the output of advisor recommendations by type
            $scriptblock.advisory.count | Should -BeExactly 4
            $scriptblock.advisory[0].gettype().Name | Should -Be 'advisorResourceObj'
            $scriptblock.advisory.where({ $_.type -eq "microsoft.subscriptions/subscriptions" }).count | Should -BeExactly 1
            $scriptblock.advisory.where({ $_.type -eq "microsoft.apimanagement/service" }).count | Should -BeExactly 3

            # Validate the output of resourcetype
            $scriptblock.resourcetype.count | Should -BeExactly 3
            $scriptblock.resourcetype.where({ $_."Available in APRL/ADVISOR?" -eq "No" }).count | Should -BeExactly 1
            $scriptblock.resourcetype.where({ $_."Available in APRL/ADVISOR?" -eq "Yes" }).count | Should -BeExactly 2

            # Validate the output of retirements
            $scriptblock.retirements.count | Should -BeExactly 3
            $scriptblock.retirements.subscription | Should -Contain "11111111-1111-1111-1111-111111111111"

            #Validate the output of support tickets
            $scriptblock.supporttickets.count | Should -BeExactly 3

            #Validate the output of service health
            $scriptblock.servicehealth.count | Should -BeExactly 9
        }
    }
}


Describe 'Build-ImpactedResourceObj' {
    Context 'When called with valid parameters' {
        BeforeAll {
            # Recommendation object hash
            $recommendationObject = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/recommendations-subset.json" | ConvertFrom-Json -Depth 10
            $recommendationObjectHash = @{}
            $recommendationObject.ForEach({ $recommendationObjectHash[$_.aprlGuid] = $_ })

            # All resources hash
            $allResources = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/all-resources-data.json" | ConvertFrom-Json -Depth 10
            $allResourcesHash = @{}
            $allResources.ForEach({ $allResourcesHash[$_.id] = $_ })
        }

        It 'Should return an array of type aprlResourceObj with a single element' {
            $impactedResource = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/impacted-resources-data-single.json" | ConvertFrom-Json -Depth 10

            InModuleScope 'wara' -Parameters @{
                ImpactedResource     = $impactedResource
                AllResources         = $allResourcesHash
                RecommendationObject = $recommendationObjectHash
            } {
                $result = Build-ImpactedResourceObj -ImpactedResources $ImpactedResource -AllResources $AllResources -RecommendationObject $RecommendationObject

                $result.GetType().FullName | Should -Be 'System.Object[]'
                $result[0].GetType().FullName | Should -Be 'aprlResourceObj'
            }
        }

        It 'Should return an array of type aprlResourceObj with multiple elements' {
            $impactedResources = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/impacted-resources-data-multiple.json" | ConvertFrom-Json -Depth 10

            InModuleScope 'wara' -Parameters @{
                ImpactedResources    = $impactedResources
                AllResources         = $allResourcesHash
                RecommendationObject = $recommendationObjectHash
            } {
                $result = Build-ImpactedResourceObj -ImpactedResources $ImpactedResources -AllResources $AllResources -RecommendationObject $RecommendationObject

                $result.GetType().FullName | Should -Be 'System.Object[]'
                $result | ForEach-Object {
                    $_.GetType().FullName | Should -Be 'aprlResourceObj'
                }
            }
        }

        It 'Should set the properties correctly' {
            $impactedResource = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/impacted-resources-data-single.json" | ConvertFrom-Json -Depth 10

            InModuleScope 'wara' -Parameters @{
                ImpactedResource     = $impactedResource
                AllResources         = $allResourcesHash
                RecommendationObject = $recommendationObjectHash
            } {
                $expected = @{
                    validationAction = 'APRL - Queries'
                    RecommendationId = $ImpactedResource.recommendationId
                    Name             = $ImpactedResource.name
                    Id               = $ImpactedResource.id
                    type             = $RecommendationObject[$ImpactedResource.recommendationId].recommendationResourceType ?? $AllResources[$ImpactedResource.id].type ?? 'Unknown'
                    location         = $AllResources[$ImpactedResource.id].location ?? 'Unknown'
                    subscriptionId   = $AllResources[$ImpactedResource.id].subscriptionId ?? $ImpactedResource.id.split('/')[2] ?? 'Unknown'
                    resourceGroup    = $AllResources[$ImpactedResource.id].resourceGroup ?? $ImpactedResource.id.split('/')[4] ?? 'Unknown'
                    Param1           = $ImpactedResource.param1 ?? ''
                    Param2           = $ImpactedResource.param2 ?? ''
                    Param3           = $ImpactedResource.param3 ?? ''
                    Param4           = $ImpactedResource.param4 ?? ''
                    Param5           = $ImpactedResource.param5 ?? ''
                    checkName        = $ImpactedResource.checkName ?? ''
                    selector         = $ImpactedResource.selector ?? 'APRL'
                }

                $result = Build-ImpactedResourceObj -ImpactedResources $ImpactedResource -AllResources $AllResources -RecommendationObject $RecommendationObject
                $actual = $result[0]

                $actual.validationAction | Should -Be $expected.validationAction
                $actual.RecommendationId | Should -Be $expected.RecommendationId
                $actual.Name | Should -Be $expected.Name
                $actual.Id | Should -Be $expected.Id
                $actual.type | Should -Be $expected.type
                $actual.location | Should -Be $expected.location
                $actual.subscriptionId | Should -Be $expected.subscriptionId
                $actual.resourceGroup | Should -Be $expected.resourceGroup
                $actual.Param1 | Should -Be $expected.Param1
                $actual.Param2 | Should -Be $expected.Param2
                $actual.Param3 | Should -Be $expected.Param3
                $actual.Param4 | Should -Be $expected.Param4
                $actual.Param5 | Should -Be $expected.Param5
                $actual.checkName | Should -Be $expected.checkName
                $actual.selector | Should -Be $expected.selector
            }
        }
    }
}

Describe 'Build-ValidationResourceObj' {

}

Describe 'Build-ResourceTypeObj' {
    Context 'When given a list of resources and the types not in aprl or advisor' {
        It 'Should return an object with the appropriate resource types' {
            $AllResources_TestData = get-content "$PSScriptRoot/../data/wara/test_allresourcesdata.json" -raw | ConvertFrom-Json -depth 20
            $RecommendationResourceTypes_TestData = get-content "$PSScriptRoot/../data/wara/test_recommendationresourcetypesdata.csv" -Raw
            $RecommendationResourceTypes = $RecommendationResourceTypes_TestData | ConvertFrom-Csv | Where-Object { $_.WARAinScope -eq 'yes' }
            $TypesNotInAPRLOrAdvisor = ($RecommendationResourceTypes | Where-Object { $_.InAprlAndOrAdvisor -eq "No" }).ResourceType


            InModuleScope 'wara' -Parameters @{
                ResourceObj             = $AllResources_TestData
                TypesNotInAPRLOrAdvisor = $TypesNotInAPRLOrAdvisor
            } {
                $result = Build-ResourceTypeObj -ResourceObj $ResourceObj -TypesNotInAPRLOrAdvisor $TypesNotInAPRLOrAdvisor

                $result.GetType().FullName | Should -Be 'System.Object[]'
                $result[0].GetType().FullName | Should -Be 'aprlResourceTypeObj'
            }

        }
    }

}

Describe 'Build-SpecializedResourceObj' {

}

Describe 'Get-WARAOtherRecommendations' {
    Context 'When given correct parameters' {
        It 'Should return the right stuff' {
            $advisorMetadata = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/test_advisormetadata.json" | ConvertFrom-Json -Depth 10
            $recommendationObject = Get-Content -Raw -LiteralPath "$PSScriptRoot/../data/wara/test_recommendationobjectdata.json" | ConvertFrom-Json -Depth 10

            InModuleScope 'wara' -Parameters @{
                RecommendationObject = $recommendationObject
                AdvisorMetadata      = $advisorMetadata
            } {
                $OtherRecommendations = Get-WARAOtherRecommendations -RecommendationObject $RecommendationObject -AdvisorMetadata $AdvisorMetadata
            }

        }
    }

}
