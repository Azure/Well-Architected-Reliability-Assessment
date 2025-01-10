BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/wara.psd1"
    Import-Module -Name $modulePath -Force
}

Describe 'Start-WARACollector' {
    It 'Should throw an exception if SubscriptionIds and ResourceGroups are not provided in Default parameter set' {
        { Start-WARACollector -TenantID '11111111-1111-1111-1111-111111111111' } | Should -Throw
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
