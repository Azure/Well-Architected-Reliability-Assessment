BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/wara.psd1"
    Import-Module -Name $modulePath -Force
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
    Context 'When given correct parameters with -passthru'{
        BeforeAll {
            $AllResources_TestData = get-content "$PSScriptRoot/../data/wara/test_allresourcesdata.json" -raw | ConvertFrom-Json -depth 20
            $QueryLoop_TestData = get-content "$PSScriptRoot/../data/wara/test_queryloopdata.json" -raw | ConvertFrom-Json -depth 20
            $AdvisorMeta_TestData = get-content "$PSScriptRoot/../data/wara/test_advisormetadata.json" -raw | ConvertFrom-Json -depth 20
            $RecommendationObject_TestData = get-content "$PSScriptRoot/../data/wara/test_recommendationobjectdata.json" -raw | ConvertFrom-Json -depth 20
            $TaggedResourceGroup_TestData = @("/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-B1")
            $TaggedResource_TestData = @("/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-A1/providers/Microsoft.ApiManagement/service/apiService1")

            Mock Connect-WAFAzure {write-host "Mocked Connect-WAFAzure"}

            Mock Invoke-WAFQuery {return $AllResources_TestData} -ParameterFilter {
                $SubscriptionIds -eq "11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222"
            }

            Mock Invoke-WAFQueryLoop {return $QueryLoop_TestData}

            Mock Get-WAFAdvisorMetadata {return $AdvisorMeta_TestData}

            Mock Invoke-RestMethod {return $RecommendationObject_TestData} -ParameterFilter {$uri -eq 'https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/data/recommendations.json'}

            Mock Get-WARAOtherRecommendations {return $null}

            Mock Get-WAFAdvisorRecommendation {return $Advisor_TestData}\

            Mock Get-WAFTaggedResourceGroup {return $TaggedResourceGroup_TestData}

            Mock Get-WAFTaggedResource {return $TaggedResource_TestData}

        }
        It 'Should run and return an object that can be measured' {
            $tenantId = $(New-Guid).Guid
            $test_subscriptionIds = "11111111-1111-1111-1111-111111111111", "22222222-2222-2222-2222-222222222222"
            $scriptBlock = Start-WARACollector -TenantID $tenantId -SubscriptionIds $test_subscriptionIds -PassThru
        }
    }
}


Describe 'Build-ImpactedResourceObj' {

}

Describe 'Build-ValidationResourceObj' {

}

Describe 'Build-ResourceTypeObj' {

}

Describe 'Build-SpecializedResourceObj' {

}

Describe 'Get-WARAOtherRecommendations' {

}
