BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/advisor/advisor.psm1"
    $testDataPath = "$PSScriptRoot/../data/bigAdvisorTestData.json"
    Import-Module -Name $modulePath -Force
        $objectlist = get-content $testDataPath -Raw | ConvertFrom-Json -depth 10
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
