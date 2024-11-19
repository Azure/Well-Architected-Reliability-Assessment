BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/advisor/advisor.psd1" 
    $testDataPath = "$PSScriptRoot/../data/advisor/bigAdvisorTestData.json"
    Import-Module -Name $modulePath -Force
    $objectlist = get-content $testDataPath -Raw | ConvertFrom-Json -depth 20
    Mock Invoke-WAFQuery { return $objectlist } -ModuleName advisor
}
Describe "Build-WAFAdvisorObject" {
    Context "When given a raw list of advisories" {
        It "Should return the processed list as object" {
            $result = Build-WAFAdvisorObject -AdvQueryResult $objectlist
            $result | Should -HaveCount 448
            $result.recommendationId    | Should -Contain '242639fd-cd73-4be2-8f55-70478db8d1a5'
            $result.type                | Should -Contain 'microsoft.subscriptions/subscriptions'
            $result.name                | Should -Contain '5555555-5555-5555-5555-555555555555'
            $result.id                  | Should -Contain '/subscriptions/5555555-5555-5555-5555-555555555555'
            $result.subscriptionId      | Should -Contain '5555555-5555-5555-5555-555555555555'
            $result.resourceGroup       | Should -Contain 'N/A'
            $result.location            | Should -Contain 'global'
            $result.category            | Should -Contain 'HighAvailability'
            $result.impact              | Should -Contain 'High'
            $result.description         | Should -Contain 'Create an Azure Service Health alert'
        }
    }
}

Describe "Get-WAFAdvisorRecommendations" {
    Context "When given a valid subscription id" {
        It "Should return the corresponding advisories" {
            $result = Get-WAFAdvisorRecommendations -Subid @('0000000-0000-0000-0000-000000000000','1111111-1111-1111-1111-111111111111','2222222-2222-2222-2222-222222222222','3333333-3333-3333-3333-333333333333','4444444-4444-4444-4444-444444444444','5555555-5555-5555-5555-555555555555','6666666-6666-6666-6666-666666666666','7777777-7777-7777-7777-777777777777') -HighAvailability
            $result | Should -HaveCount 448
            $result.recommendationId    | Should -Contain '242639fd-cd73-4be2-8f55-70478db8d1a5'
            $result.type                | Should -Contain 'microsoft.subscriptions/subscriptions'
            $result.name                | Should -Contain '5555555-5555-5555-5555-555555555555'
            $result.id                  | Should -Contain '/subscriptions/5555555-5555-5555-5555-555555555555'
            $result.subscriptionId      | Should -Contain '5555555-5555-5555-5555-555555555555'
            $result.resourceGroup       | Should -Contain 'N/A'
            $result.location            | Should -Contain 'global'
            $result.category            | Should -Contain 'HighAvailability'
            $result.impact              | Should -Contain 'High'
            $result.description         | Should -Contain 'Create an Azure Service Health alert'
        }
    }
}
