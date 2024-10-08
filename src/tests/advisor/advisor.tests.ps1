BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/advisor/advisor.psm1"
    $testDataPath = "$PSScriptRoot/../data/newAdvisorData.json"
    Import-Module -Name $modulePath -Force
        $objectlist = get-content $testDataPath -Raw | ConvertFrom-Json -depth 10
}

Describe "Build-WAFAdvisorObject" {
    Context "When given a raw list of advisories" {
        It "Should return the processed list as object" {
            $result = Build-WAFAdvisorObject -AdvQueryResult $objectlist
            $result | Should -HaveCount 2
            $result.recommendationId    | Should -Contain 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA'
            $result.type                | Should -Contain 'MICROSOFT.CONTAINERSERVICE/MANAGEDCLUSTERS'
            $result.name                | Should -Contain 'AKSCLUSTER01'
            $result.id                  | Should -Contain '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/RESOURCEGROUP01/providers/Microsoft.ContainerService/managedClusters/AKSCLUSTER01'
            $result.subscriptionId      | Should -Contain '11111111-1111-1111-1111-111111111111'
            $result.resourceGroup       | Should -Contain 'RESOURCEGROUP01'
            $result.location            | Should -Contain 'centralus'
            $result.category            | Should -Contain 'HighAvailability'
            $result.impact              | Should -Contain 'High'
            $result.description         | Should -Contain 'Enable Autoscaling for your system node pools'
        }
    }
}
