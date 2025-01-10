BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/wara.psd1"
    Import-Module -Name $modulePath -Force
}

Describe 'Start-WARACollector' {
    It 'Should throw an exception if SubscriptionIds and ResourceGroups are not provided in Default parameter set' {
        { Start-WARACollector -TenantID '11111111-1111-1111-1111-111111111111' } | Should -Throw
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

}

Describe 'Build-SpecializedResourceObj' {

}

Describe 'Get-WARAOtherRecommendations' {

}
