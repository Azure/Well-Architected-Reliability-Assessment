BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/wara.psd1"
    Import-Module -Name $modulePath -Force
}

Describe 'Start-WARACollector' {
    Context 'When given the Default parameter set without SubscriptionIds and ResourceGroups' {
        It 'Should throw an exception with the specified message' {
            $scriptBlock = { Start-WARACollector -TenantID '11111111-1111-1111-1111-111111111111' }
            $scriptBlock | Should -Throw -ExpectedMessage 'The parameter SubscriptionIds or ResourceGroups is required when using the Default parameter set.'
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
