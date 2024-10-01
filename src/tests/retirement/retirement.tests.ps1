BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/retirement/retirement.psm1"
    Import-Module -Name $modulePath -Force
}

Describe 'Get-AzureRestMethodUriPath' {
    Context 'When to get an Azure REST API URI path' {
        It 'Should return the path that does contains resource group' {
            $result = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceGroupName 'test1' -ResourceProviderName 'Microsoft.Compute' -ResourceType 'virtualMachines' -Name 'TestVM1' -ApiVersion '0000-00-00'
            $result | Should -BeExactly '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1?api-version=0000-00-00'
        }

        It 'Should return the path that does contains resource group with query string' {
            $result = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceGroupName 'test1' -ResourceProviderName 'Microsoft.Compute' -ResourceType 'virtualMachines' -Name 'TestVM1' -ApiVersion '0000-00-00' -QueryString 'test=test'
            $result | Should -BeExactly '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1?api-version=0000-00-00&test=test'
        }

        It 'Should return the path that does not contains resource group' {
            $result = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceProviderName 'Microsoft.ResourceHealth' -ResourceType 'events' -ApiVersion '0000-00-00'
            $result | Should -BeExactly '/subscriptions/11111111-1111-1111-1111-111111111111/providers/Microsoft.ResourceHealth/events?api-version=0000-00-00'
        }

        It 'Should return the path that does not contains resource group with query string' {
            $result = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceProviderName 'Microsoft.ResourceHealth' -ResourceType 'events' -ApiVersion '0000-00-00' -QueryString 'test=test'
            $result | Should -BeExactly '/subscriptions/11111111-1111-1111-1111-111111111111/providers/Microsoft.ResourceHealth/events?api-version=0000-00-00&test=test'
        }
    }
}

Describe 'Invoke-AzureRestApi' {
}

Describe 'New-WAFResourceRetirementObject' {
    Context 'When to get a RetirementObject' {
        BeforeAll {
$descriptionText = @'
<p><em>You're receiving this notice because you're an Azure customer.</em></p>
<p>To enhance security and provide best-in-class encryption for your data,&nbsp;<strong>we'll require interactions with Azure services to be secured using Transport Layer Security (TLS) 1.2 or later beginning 31 October 2024</strong>, when support for TLS 1.0 and 1.1 will end.</p>
<p>The Microsoft implementation of older TLS versions is not known to be vulnerable, however, TLS 1.2 and later offer improved security with features such as perfect forward secrecy and stronger cipher suites.</p>
<h2>Recommended action</h2>
<p>To avoid potential service disruptions,&nbsp;<strong>confirm that&nbsp;your resources that interact with Azure services are using TLS 1.2 or later</strong>. Then:</p>
<p></p><ul><li>If they're already exclusively using TLS 1.2 or later, you don't need to take further action.</li><li>If they still have a dependency on TLS 1.0 or 1.1,&nbsp;<strong>transition&nbsp;them to TLS 1.2 or later by 31 October 2024</strong>.</li></ul><h2>Help and support</h2><p>Read more about the&nbsp;<a href="https://aka.ms/RemoveLegacyTLS" target="_blank">update to TLS 1.2</a>. If you have questions, get answers from community experts in&nbsp;<a href="https://aka.ms/azureqa" target="_blank">Microsoft Q&amp;A</a>. If you have a support plan and you need technical help, please create a&nbsp;<a href="https://learn.microsoft.com/azure/azure-portal/supportability/how-to-create-azure-support-request" target="_blank">support request</a>.</p><p></p>
'@

            $cmdletParams = @{
                SubscriptionId  = '11111111-1111-1111-1111-111111111111'
                TrackingId      = 'XXXX-XXX'
                Status          = 'Active'
                LastUpdateTime  = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                Starttime       = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                Endtime         = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                Level           = 'Warning'
                Title           = 'Azure Product Retirement: Azure Automanage Best Practices retires on 30 September 2027'
                Summary         = "<p><strong><em>You're receiving this notice because you're currently using Automanage Best Practices.</em></strong></p>"
                Header          = 'Your service might have been impacted by an Azure service issue'
                ImpactedService = $null  # Set per test case.
                Description     = $descriptionText
            }
        }

        It 'Should return a RetirementObject with a single impacted service' {
            $cmdletParams.ImpactedService = 'Network Infrastructure'
            $result = New-WAFResourceRetirementObject @cmdletParams

            $result.Subscription | Should -BeExactly $cmdletParams.SubscriptionId
            $result.TrackingId | Should -BeExactly $cmdletParams.TrackingId
            $result.Status | Should -BeExactly $cmdletParams.Status
            $result.LastUpdateTime | Should -BeExactly $cmdletParams.LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
            $result.Starttime | Should -BeExactly $cmdletParams.Starttime.ToString('yyyy-MM-dd HH:mm:ss')
            $result.Endtime | Should -BeExactly $cmdletParams.Endtime.ToString('yyyy-MM-dd HH:mm:ss')
            $result.Level | Should -BeExactly $cmdletParams.Level
            $result.Title | Should -BeExactly $cmdletParams.Title
            $result.Summary | Should -BeExactly $cmdletParams.Summary
            $result.Header | Should -BeExactly $cmdletParams.Header
            $result.ImpactedService | Should -BeExactly ($cmdletParams.ImpactedService -join ', ')
            $result.Description | Should -BeExactly $cmdletParams.Description
        }

        It 'Should return a RetirementObject with multiple impacted services' {
            $cmdletParams.ImpactedService = 'Network Infrastructure', 'Azure Database for MySQL', 'Automation'
            $result = New-WAFResourceRetirementObject @cmdletParams

            $result.Subscription | Should -BeExactly $cmdletParams.SubscriptionId
            $result.TrackingId | Should -BeExactly $cmdletParams.TrackingId
            $result.Status | Should -BeExactly $cmdletParams.Status
            $result.LastUpdateTime | Should -BeExactly $cmdletParams.LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
            $result.Starttime | Should -BeExactly $cmdletParams.Starttime.ToString('yyyy-MM-dd HH:mm:ss')
            $result.Endtime | Should -BeExactly $cmdletParams.Endtime.ToString('yyyy-MM-dd HH:mm:ss')
            $result.Level | Should -BeExactly $cmdletParams.Level
            $result.Title | Should -BeExactly $cmdletParams.Title
            $result.Summary | Should -BeExactly $cmdletParams.Summary
            $result.Header | Should -BeExactly $cmdletParams.Header
            $result.ImpactedService | Should -BeExactly ($cmdletParams.ImpactedService -join ', ')
            $result.Description | Should -BeExactly $cmdletParams.Description
        }
    }
}

Describe 'Get-WAFResourceRetirement' {
}
