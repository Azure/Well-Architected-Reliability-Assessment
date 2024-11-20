using module ../../modules/wara/servicehealth/servicehealth.psd1

BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/servicehealth/servicehealth.psd1"
    Import-Module -Name $modulePath -Force
    $test_ServicehealthData_FilePath = "$PSScriptRoot/../data/servicehealth/servicehealthdata.json"
    $test_ServicehealthData = Get-Content $test_ServicehealthData_FilePath -raw | ConvertFrom-Json -depth 20
    Mock Invoke-WAFQuery { return $test_ServicehealthData } -module servicehealth -Verifiable
}

Describe 'Get-WAFServiceHealth' {
    Context 'When the function is called and mocked with test data' {
        It 'Should return a valid list of ServiceHealthAlert objects' {
            $SubscriptionIds = @('00000000-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111')
            $ServiceHealthAlert = Get-WAFServiceHealth -SubscriptionIds $SubscriptionIds
            $ServiceHealthAlert.count | Should -Be 9
            $ServiceHealthAlert.Name | Should -Contain 'ServiceHealthIncident'
            $ServiceHealthAlert.Subscription | Should -Contain 'Contoso Prod'
            $ServiceHealthAlert.Subscription | Should -Contain 'Contoso PreProd'
            $ServiceHealthAlert.Enabled | Should -Contain 'True'
            $ServiceHealthAlert.EventType | Should -Contain 'All'
            $ServiceHealthAlert.Services | Should -Contain 'All'
            $ServiceHealthAlert.Regions | Should -Contain 'All'
            $ServiceHealthAlert.ActionGroup | Should -Contain 'ag-01'
            $ServiceHealthAlert.ActionGroup | Should -Contain 'ag-02'
        }
    }
}

Describe 'Build-WAFServiceHealthObject' {
    Context 'When the function is called with a valid query result' {
        It 'Should return a list of ServiceHealthAlert objects' {
            $ServiceHealthAlert = Build-WAFServiceHealthObject -AdvQueryResult $test_ServicehealthData
            $ServiceHealthAlert.count | Should -Be 9
            $ServiceHealthAlert.Name | Should -Contain 'ServiceHealthIncident'
            $ServiceHealthAlert.Subscription | Should -Contain 'Contoso Prod'
            $ServiceHealthAlert.Subscription | Should -Contain 'Contoso PreProd'
            $ServiceHealthAlert.Enabled | Should -Contain 'True'
            $ServiceHealthAlert.EventType | Should -Contain 'All'
            $ServiceHealthAlert.Services | Should -Contain 'All'
            $ServiceHealthAlert.Regions | Should -Contain 'All'
            $ServiceHealthAlert.ActionGroup | Should -Contain 'ag-01'
            $ServiceHealthAlert.ActionGroup | Should -Contain 'ag-02'
        }
        It 'Should contain the following counts of properties - EventType' {
            $ServiceHealthAlert = Build-WAFServiceHealthObject -AdvQueryResult $test_ServicehealthData
            $ServiceHealthAlert_CountOfAll = $ServiceHealthAlert | Group-Object -Property EventType | Select-Object Name, Count | Where-Object-Object { $_.Name -eq 'All' }
            $ServiceHealthAlert_CountOfServiceIssues = $ServiceHealthAlert | Group-Object -Property EventType | Select-Object Name, Count | Where-Object-Object { $_.Name -eq 'Service Issues' }
            $ServiceHealthAlert_CountOfSecurityAdvisory = $ServiceHealthAlert | Group-Object -Property EventType | Select-Object Name, Count | Where-Object-Object { $_.Name -eq 'Security Advisory' }
            $ServiceHealthAlert_CountOfPlannedMaintenance = $ServiceHealthAlert | Group-Object -Property EventType | Select-Object Name, Count | Where-Object-Object { $_.Name -eq 'Planned Maintenance' }

            $ServiceHealthAlert_CountOfAll.Count | Should -Be 3
            $ServiceHealthAlert_CountOfServiceIssues.Count | Should -Be 2
            $ServiceHealthAlert_CountOfSecurityAdvisory.Count | Should -Be 2
            $ServiceHealthAlert_CountOfPlannedMaintenance.Count | Should -Be 2
        }
    }
}

Describe 'ServiceHealthAlert' {
    Context 'When the class is called with a valid query result' {
        It 'Should return a valid ServiceHealthAlert object' {
            $ServiceHealthAlert = [ServiceHealthAlert]::new($test_ServicehealthData[0])
            $ServiceHealthAlert.Name | Should -Be 'ServiceHealthSecurityIncident'
            $ServiceHealthAlert.Subscription | Should -Be 'Contoso PreProd'
            $ServiceHealthAlert.Enabled | Should -Be 'True'
            $ServiceHealthAlert.EventType | Should -Be 'All'
            $ServiceHealthAlert.Services | Should -Be 'All'
            $ServiceHealthAlert.Regions | Should -Be 'All'
            $ServiceHealthAlert.ActionGroup | Should -Be 'ag-01'
        }
    }

    Context 'When the class methods are called with a valid query result' {
        BeforeAll {
            $AlertWithMostParameters = $test_ServicehealthData | Where-Object {$_.eventName -eq "srvc-pm-alert"}
            [void]$AlertWithMostParameters
        }

        It '[ServiceHealthAlert]::GetEventType() should return a valid EventType' {
            $EventType = [ServiceHealthAlert]::GetEventType($test_ServicehealthData[1])
            $EventType | Should -Be 'Security Advisory'
        }
        It '[ServiceHealthAlert]::GetServices() should return a valid Services' {
            $Services = [ServiceHealthAlert]::GetServices($AlertWithMostParameters)
            $Services | Should -Be 'Azure Container Registry, Azure Database for PostgreSQL, Azure Database for PostgreSQL flexible servers, Azure Kubernetes Service (AKS), Storage, Virtual Network'
        }
        It '[ServiceHealthAlert]::GetRegions() should return a valid Regions' {
            $Regions = [ServiceHealthAlert]::GetRegions($AlertWithMostParameters)
            $Regions | Should -Be 'Central US, East US 2, UK South, UK West'
        }
        It '[ServiceHealthAlert]::GetActionGroupName() should return a valid ActionGroupName' {
            $ActionGroupName = [ServiceHealthAlert]::GetActionGroupName($test_ServicehealthData[0])
            $ActionGroupName | Should -Be 'ag-01'
        }
    }
}