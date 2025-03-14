BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/advisor/advisor.psd1"
    $testDataPath = "$PSScriptRoot/../data/advisor/bigAdvisorTestData.json"
    $test_AdvisorDataPath = "$PSScriptRoot/../data/advisor/test_advisormetadata.json"
    Import-Module -Name $modulePath -Force
    $objectlist = get-content $testDataPath -Raw | ConvertFrom-Json -depth 20
    $test_AdvisorData = get-content $test_AdvisorDataPath -raw | ConvertFrom-Json -depth 100
    Mock Invoke-WAFQuery { return $objectlist } -ModuleName advisor -Verifiable
    Mock Get-AzAccessToken { return @{
            token = ConvertTo-SecureString -String "fake-token" -AsPlainText -Force
        } } -ModuleName advisor -Verifiable
    Mock Invoke-RestMethod { return $test_AdvisorData } -ModuleName advisor -Verifiable
}

Describe 'Build-WAFAdvisorObject' {
    Context 'When given a raw list of advisories' {
        It 'Should return the processed list as object' {
            $result = Build-WAFAdvisorObject -AdvQueryResult $objectlist
            $result | Should -HaveCount 448
            $result.recommendationId    | Should -Contain '242639fd-cd73-4be2-8f55-70478db8d1a5'
            $result.type                | Should -Contain 'microsoft.subscriptions/subscriptions'
            $result.name                | Should -Contain '55555555-5555-5555-5555-555555555555'
            $result.id                  | Should -Contain '/subscriptions/55555555-5555-5555-5555-555555555555'
            $result.subscriptionId      | Should -Contain '55555555-5555-5555-5555-555555555555'
            $result.resourceGroup       | Should -Contain 'N/A'
            $result.location            | Should -Contain 'global'
            $result.category            | Should -Contain 'HighAvailability'
            $result.impact              | Should -Contain 'High'
            $result.description         | Should -Contain 'Create an Azure Service Health alert'
        }
    }
}

Describe 'Get-WAFAdvisorRecommendations' {
    Context 'When given a valid subscription id' {
        It 'Should return the corresponding advisories' {
            $result = Get-WAFAdvisorRecommendation -SubscriptionIds @('0000000-0000-0000-0000-000000000000', '1111111-1111-1111-1111-111111111111', '2222222-2222-2222-2222-222222222222', '3333333-3333-3333-3333-333333333333', '4444444-4444-4444-4444-444444444444', '5555555-5555-5555-5555-555555555555', '6666666-6666-6666-6666-666666666666', '7777777-7777-7777-7777-777777777777') -HighAvailability
            $result | Should -HaveCount 448
            $result.recommendationId    | Should -Contain '242639fd-cd73-4be2-8f55-70478db8d1a5'
            $result.type                | Should -Contain 'microsoft.subscriptions/subscriptions'
            $result.name                | Should -Contain '55555555-5555-5555-5555-555555555555'
            $result.id                  | Should -Contain '/subscriptions/55555555-5555-5555-5555-555555555555'
            $result.subscriptionId      | Should -Contain '55555555-5555-5555-5555-555555555555'
            $result.resourceGroup       | Should -Contain 'N/A'
            $result.location            | Should -Contain 'global'
            $result.category            | Should -Contain 'HighAvailability'
            $result.impact              | Should -Contain 'High'
            $result.description         | Should -Contain 'Create an Azure Service Health alert'
        }
    }
}

Describe 'Get-WAFAdvisorMetadata' {
    Context 'When the function is called' {
        It 'Should return the metadata' {
            $result = Get-WAFAdvisorMetadata
            Should -InvokeVerifiable
            $result | Should -BeOfType 'System.Object'
            $result | Should -HaveCount 1426
        }
    }
}

Describe 'advisorResourceObj' {
    BeforeAll {
        $results = InModuleScope 'advisor' -Parameters @{
            objectlist = $objectlist
        } {

            #Create a new instance of the class
            return $objectlist.foreach({ [advisorResourceObj]::new($_) })

        }
    }
    Context 'When the class is instantiated' {
        It 'Should be of type advisorResourceObj' {
            $results[0].GetType().Name | Should -Be 'advisorResourceObj'
        }
        It 'Should work with the Equals() method correctly' {
            $results[0].Equals($results[0]) | Should -BeTrue
            $results[0].Equals($results[1]) | Should -BeFalse
        }
        It 'Should have the correct properties' {

            #Get the properties of the object
            $propertynames = $results[0].psobject.Properties.name

            #Test the number of properties
            $propertynames.count | Should -Be 10

            #Test the properties
            $propertynames | Should -Contain 'recommendationId'
            $propertynames | Should -Contain 'type'
            $propertynames | Should -Contain 'name'
            $propertynames | Should -Contain 'id'
            $propertynames | Should -Contain 'subscriptionId'
            $propertynames | Should -Contain 'resourceGroup'
            $propertynames | Should -Contain 'location'
            $propertynames | Should -Contain 'category'
            $propertynames | Should -Contain 'impact'
            $propertynames | Should -Contain 'description'
        }
        It 'Should be able to be sorted as a collection and remove duplicates using Linq Distinct method' {

            #Test the count of the collection
            $results | Should -HaveCount 448

            #Test the sorting of the collection
            #Create duplicates in the collection by multiplying it by 10
            $results = $results * 10

            #Count the collection with duplicates
            $results | Should -HaveCount 4480

            #Sort the $results collection using Linq Distinct method
            $FilteredResources = [System.Linq.Enumerable]::Distinct([object[]]$results).toArray()

            #Count the collection after removing duplicates
            $FilteredResources | Should -HaveCount 448
        }
    }
}
