BeforeAll{
    #Import the module
    import-module -Name "$PSScriptRoot/../../modules/wara/collector/collector.psd1" -Force

    #Import the test data and only return the full resourceIds (Should be 445 of these)
    $test_resourceIds = (get-content ".\src\tests\data\collector\test_resourceids.json" -raw |convertfrom-json -depth 20)
}

Describe 'Get-WAFTaggedResource'{
    Context 'Should return a list of resourceIds where the count is greater than the number of items in the tagArray'{
        It 'Should return a list of resourceIds'{
            #These variables do not actually matter, we're mocking the data, but we need at least two tags to test the function appropriately.
            $tagArray = @('key1=~value1', 'key2=~value2')
            $test_tagkeys = @('key1', 'key2')
            $SubscriptionIds = @('sub1', 'sub2')

            #We need to create duplicates in some of the resourceids to ensure that the function is working correctly.
            #Adding 100 duplicates of the first 100 resourceIds
            Mock Invoke-WAFQuery { return $test_ResourceIds }  -ParameterFilter {$query -and $query.contains($test_tagkeys[0])} -module collector -Verifiable
            Mock Invoke-WAFQuery { return $test_ResourceIds[0..9] } -ParameterFilter {$query -and $query.contains($test_tagkeys[1])} -module collector -Verifiable

            #Because we are adding duplicates, the count should be 100
            $resourceIds = Get-WAFTaggedResource -Debug -tagArray $tagArray -SubscriptionIds $SubscriptionIds
            Should -InvokeVerifiable

            $resourceIds.count | Should -Be 10
        }
    }
}