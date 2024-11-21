BeforeAll {
    #Import the module
    import-module -Name "$PSScriptRoot/../../modules/wara/collector/collector.psd1" -Force

    #Import the test data and only return the full resourceIds (Should be 445 of these)
    $test_resourceIds = (get-content ".\src\tests\data\collector\test_resourceids.json" -raw | convertfrom-json -depth 20)
    $test_resourcegroupIds = (get-content ".\src\tests\data\collector\test_resourcegroupids.json" -raw | convertfrom-json -depth 20)

    #Import the Recommendation Object from the collector test data
    $test_RecommendationObject = (get-content ".\src\tests\data\collector\test_RecommendationObject.json" -raw | convertfrom-json -depth 20)

    #Import the Type list from the collector test data
    $test_Types = (get-content ".\src\tests\data\collector\test_types.json" -raw | convertfrom-json -depth 20)

    #Import the test advisor responses from test data
    $test_AdvisorData = (get-content ".\src\tests\data\wara\wafquerydata-sanitized.json" -raw | convertfrom-json -depth 20)
}

Describe 'Get-WAFTaggedResource' {
    Context 'Should return a list of resourceIds where the count is greater than the number of items in the tagArray' {
        It 'Should return a list of resourceIds' {
            #These variables do not actually matter, we're mocking the data, but we need at least two tags to test the function appropriately.
            $tagArray = @('key1=~value1', 'key2=~value2')
            $test_tagkeys = @('key1', 'key2')
            $SubscriptionIds = @('sub1', 'sub2')

            #We need to create duplicates in some of the resourceids to ensure that the function is working correctly.
            #Adding 100 duplicates of the first 100 resourceIds
            Mock Invoke-WAFQuery { return $test_ResourceIds }  -ParameterFilter { $query -and $query.contains($test_tagkeys[0]) } -module collector -Verifiable
            Mock Invoke-WAFQuery { return $test_ResourceIds[0..9] } -ParameterFilter { $query -and $query.contains($test_tagkeys[1]) } -module collector -Verifiable

            #Because we are adding duplicates, the count should be 100
            $resourceIds = Get-WAFTaggedResource -Debug -tagArray $tagArray -SubscriptionIds $SubscriptionIds
            Should -InvokeVerifiable

            $resourceIds.count | Should -Be 10
        }
    }
}

Describe 'Get-WAFTaggedResourceGroup' {
    Context 'Should return a list of resourceIds where the count is greater than the number of items in the tagArray' {
        It 'Should return a list of resourceIds' {
            #These variables do not actually matter, we're mocking the data, but we need at least two tags to test the function appropriately.
            $tagArray = @('key1=~value1', 'key2=~value2')
            $test_tagkeys = @('key1', 'key2')
            $SubscriptionIds = @('sub1', 'sub2')

            #We need to create duplicates in some of the resourceids to ensure that the function is working correctly.
            #Adding 100 duplicates of the first 100 resourceIds
            Mock Invoke-WAFQuery { return $test_ResourcegroupIds }  -ParameterFilter { $query -and $query.contains($test_tagkeys[0]) } -module collector -Verifiable
            Mock Invoke-WAFQuery { return $test_ResourcegroupIds[0..9] } -ParameterFilter { $query -and $query.contains($test_tagkeys[1]) } -module collector -Verifiable

            #Because we are adding duplicates, the count should be 100
            $resourceIds = Get-WAFTaggedResourceGroup -Debug -tagArray $tagArray -SubscriptionIds $SubscriptionIds
            Should -InvokeVerifiable

            $resourceIds.count | Should -Be 10
        }
    }
}

Describe 'Invoke-WAFQueryLoop' {
    Context 'When given a recommendation object and a list of subscriptionIds' {
        It 'Should return a list of resources' {

            
            #Mock the Get-WAFResourceType function to return the test data
            Mock Get-WAFResourceType { return $test_Types } -module collector -Verifiable
            
            #Mock the Invoke-WAFQuery function to return the test data
            Mock Invoke-WAFQuery { return $test_AdvisorData[0..9] } -module collector -Verifiable
            
            #Run the function
            $resources = Invoke-WAFQueryLoop -RecommendationObject $test_RecommendationObject -subscriptionIds @('sub1')
            Should -InvokeVerifiable

            #Check that the count of resources is correct
            $resources.count | Should -Be 810
        }
    }
}

Describe 'Get-WAFQueryByResourceType' {
    Context 'When given a current recommendation object and a good filter list' {
        It 'Should return the correct list of recommendations' {
            
            #Run the function
            $QueryObject = Get-WAFQueryByResourceType -ObjectList $test_RecommendationObject -FilterList $test_Types.type -KeyColumn "recommendationResourceType"
            
            #Check that the number of recommendations equals the correct amount for the test data (test_recommendationobject and test_types)
            $QueryObject.count | Should -Be 166

            #Check that the count of each recommendationResourceType is correct
            ($QueryObject | Group-Object -Property recommendationResourceType).count | Should -be 26

            #Check individual counts of each recommendationResourceType
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Compute/virtualMachines' }).count | Should -Be 28
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Automation/automationAccounts' }).count | Should -Be 1
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.CognitiveServices/Accounts' }).count | Should -Be 1
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Compute/disks' }).count | Should -Be 2
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Compute/virtualMachineScaleSets' }).count | Should -Be 9
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.ContainerRegistry/registries' }).count | Should -Be 10
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.ContainerService/managedClusters' }).count | Should -Be 25
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Dashboard/grafana' }).count | Should -Be 1
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Insights/activityLogAlerts' }).count | Should -Be 1
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Insights/components' }).count | Should -Be 1
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.KeyVault/vaults' }).count | Should -Be 5
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/applicationGateways' }).count | Should -Be 9
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/loadBalancers' }).count | Should -Be 5
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/networkSecurityGroups' }).count | Should -Be 4
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/networkWatchers' }).count | Should -Be 5
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/privateEndpoints' }).count | Should -Be 1
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/publicIPAddresses' }).count | Should -Be 4
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/routeTables' }).count | Should -Be 2
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/trafficManagerProfiles' }).count | Should -Be 5
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Network/virtualNetworks' }).count | Should -Be 3
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.OperationalInsights/workspaces' }).count | Should -Be 2
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.RecoveryServices/vaults' }).count | Should -Be 5
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Sql/servers' }).count | Should -Be 9
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Storage/storageAccounts' }).count | Should -Be 9
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Web/serverFarms' }).count | Should -Be 5
            ($QueryObject | Group-object -Property recommendationResourceType | Select-Object Name, Count | Where-Object { $_.Name -eq 'Microsoft.Web/sites' }).count | Should -Be 14
        }
    }
}

Describe 'Get-WAFResourceType' {
    Context 'When given a list of subscriptionIds' {
        It 'Should return a list of resource types' {
            #Mock the Invoke-WAFQuery function to return the test data
            Mock Invoke-WAFQuery { return $test_Types } -module collector -Verifiable

            #Run the function
            $Types = Get-WAFResourceType -SubscriptionIds @('sub1')
            Should -InvokeVerifiable

            #Check that the count of resources is correct
            $Types.count | Should -Be 61
        }
    }
}