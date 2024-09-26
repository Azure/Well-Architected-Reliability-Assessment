
BeforeAll {
    $modulePath = "$PSScriptRoot/../modules/wara/scope/scope.psm1"
    $testDataPath = "$PSScriptRoot/data/newResourceData.json"
    Import-Module -Name $modulePath -Force
        $objectlist = get-content $testDataPath -Raw | ConvertFrom-Json -depth 10
        $SubscriptionFilterList = @('/subscriptions/11111111-1111-1111-1111-111111111111', '/subscriptions/33333333-3333-3333-3333-333333333333')
        $ResourceGroupFilterList = @('/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/test2', '/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/test4')
        $ResourceFilterList = @('/subscriptions/77777777-7777-7777-7777-777777777777/resourceGroups/test7/providers/Microsoft.Compute/virtualMachines/TestVM7', '/subscriptions/66666666-6666-6666-6666-666666666666/resourceGroups/test6/providers/Microsoft.Compute/virtualMachines/TestVM6')
        $KeyColumn = 'id'
}
Describe "Get-WAFSubscriptionsByList" {
    Context "When given a valid list of subscriptions" {
        It "Should return the corresponding subscriptions" {
            $result = Get-WAFSubscriptionsByList -ObjectList $ObjectList -FilterList $SubscriptionFilterList -KeyColumn $keycolumn
            $result | Should -HaveCount 2
            $result.id | Should -Contain '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1'
            $result.id | Should -Contain '/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/test3/providers/Microsoft.Compute/virtualMachines/TestVM3'
        }
    }
}

Describe "Get-WAFResourceGroupsByList" {
    Context "When given a valid list of resource groups" {
        It "Should return the corresponding resource ids that match the resource groups" {
            $result = Get-WAFResourceGroupsByList -ObjectList $ObjectList -FilterList $ResourceGroupFilterList -KeyColumn $keycolumn
            $result | Should -HaveCount 2
            $result.id | Should -Contain '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/test2/providers/Microsoft.Compute/virtualMachines/TestVM2'
            $result.id | Should -Contain '/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/test4/providers/Microsoft.Compute/virtualMachines/TestVM4'
        }
    }
}

Describe "Get-WAFResourcesByList" {
    Context "When given a valid list of resource ids" {
        It "Should return the corresponding resource ids that match the resource ids in the filter" {
            $result = Get-WAFResourcesByList -ObjectList $ObjectList -FilterList $ResourceFilterList -KeyColumn $keycolumn
            $result | Should -HaveCount 2
            $result.id | Should -Contain '/subscriptions/77777777-7777-7777-7777-777777777777/resourceGroups/test7/providers/Microsoft.Compute/virtualMachines/TestVM7'
            $result.id | Should -Contain '/subscriptions/66666666-6666-6666-6666-666666666666/resourceGroups/test6/providers/Microsoft.Compute/virtualMachines/TestVM6'
        }
    }
}

Describe "Get-WAFFilteredResourceList" {
    Context "When given a valid list of resource ids, resource groups, and subscriptions it should filter the list and only return resourceids that are in scope." {
        It "Should return the corresponding resource ids that match the resource ids" {
            $result = Get-WAFFilteredResourceList -UnfilteredResources $ObjectList -ResourceFilters $ResourceFilterList -ResourceGroupFilters $ResourceGroupFilterList -SubscriptionFilters $SubscriptionFilterList -KeyColumn $KeyColumn
            $result | Should -HaveCount 6
            $result.id | Should -Contain '/subscriptions/77777777-7777-7777-7777-777777777777/resourceGroups/test7/providers/Microsoft.Compute/virtualMachines/TestVM7'
            $result.id | Should -Contain '/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/test3/providers/Microsoft.Compute/virtualMachines/TestVM3'
            $result.id | Should -Contain '/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1'
            $result.id | Should -Contain '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/test2/providers/Microsoft.Compute/virtualMachines/TestVM2'
            $result.id | Should -Contain '/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/test4/providers/Microsoft.Compute/virtualMachines/TestVM4'
            $result.id | Should -Contain '/subscriptions/66666666-6666-6666-6666-666666666666/resourceGroups/test6/providers/Microsoft.Compute/virtualMachines/TestVM6'
            
        }
    }
}