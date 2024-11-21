BeforeAll{
    #Import the module
    import-module -Name "$PSScriptRoot/../../modules/wara/collector/collector.psd1" -Force

    #Import the test data and only return the full resourceIds (Should be 445 of these)
    $test_resourceIds = (get-content .\src\tests\data\advisor\bigAdvisorTestData.json -raw |convertfrom-json -depth 20).id | where {$_.split("/").count -gt 4}
}

Describe 'Get-WAFTaggedResource'{
    Context 'Should return a list of resourceIds where the count is greater than the number of items in the tagArray'{
        It 'Should return a list of resourceIds'{
            #These variables do not actually matter, we're mocking the data, but we need at least two tags to test the function appropriately.
            $tagArray = @('key1=~value1', 'key2=~value2')
            $SubscriptionIds = @('sub1', 'sub2')

            #We need to create duplicates in some of the resourceids to ensure that the function is working correctly.
            #Adding 100 duplicates of the first 100 resourceIds
            $test_taggedResourceIds = $test_resourceIds + $test_resourceIds[0..99]
            Mock Invoke-WAFQuery { return $test_taggedResourceIds } -ParameterFilter {} -module collector -Verifiable

            #Because we are adding duplicates, the count should be 100
            $resourceIds = Get-WAFTaggedResource -tagArray $tagArray -SubscriptionIds $SubscriptionIds
            $resourceIds.count | Should -Be 100
        }
    }
}