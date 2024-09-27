Function Test-Export{
    $SubscriptionFilterList = @('/subscriptions/11111111-1111-1111-1111-111111111111', '/subscriptions/33333333-3333-3333-3333-333333333333')
        $ResourceGroupFilterList = @('/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/test2', '/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/test4')
        $ResourceFilterList = @('/subscriptions/77777777-7777-7777-7777-777777777777/resourceGroups/test7/providers/Microsoft.Compute/virtualMachines/TestVM7', '/subscriptions/66666666-6666-6666-6666-666666666666/resourceGroups/test6/providers/Microsoft.Compute/virtualMachines/TestVM6')
        $KeyColumn = 'id'

        $result = Get-WAFImplicitSubscriptionId -SubscriptionFilters $SubscriptionFilterList -ResourceGroupFilters $ResourceGroupFilterList -ResourceFilters $ResourceFilterList
        return $result
}