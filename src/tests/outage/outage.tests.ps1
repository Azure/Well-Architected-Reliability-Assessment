BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/outage/outage.psd1"
    Import-Module -Name $modulePath -Force
    Import-Module -Name 'Az.Accounts' -Force
}


Describe 'New-WAFOutageObject' {
    Context 'When to get an OutageObject' {
        BeforeAll {
            $outageDescriptionFilePath = "$PSScriptRoot/../data/outage/outageDescriptionData.txt"
        }

        BeforeEach {
            $commonCmdletParams = @{
                SubscriptionId  = '11111111-1111-1111-1111-111111111111'
                TrackingId      = 'XXXX-XXX'
                Status          = 'Active'
                LastUpdateTime  = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                StartTime       = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                EndTime         = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                Level           = 'Warning'
                Title           = 'Mitigated - Storage Metrics UI Regression Impacting Non-Classic Storage Accounts in Azure Monitor'
                Summary         = "<p><strong>What happened?</strong></p>"
                Header          = 'Your service might have been impacted by an Azure service issue'
                Description     = Get-Content $outageDescriptionFilePath -Raw
            }

            $expected = @{
                subscription    = $commonCmdletParams.SubscriptionId
                trackingId      = $commonCmdletParams.TrackingId
                status          = $commonCmdletParams.Status
                lastUpdateTime  = $commonCmdletParams.LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
                startTime       = $commonCmdletParams.StartTime.ToString('yyyy-MM-dd HH:mm:ss')
                endTime         = $commonCmdletParams.EndTime.ToString('yyyy-MM-dd HH:mm:ss')
                level           = $commonCmdletParams.Level
                title           = $commonCmdletParams.Title
                summary         = $commonCmdletParams.Summary
                header          = $commonCmdletParams.Header
                description     = $commonCmdletParams.Description
            }
        }

        It 'Should return an OutageObject with a single impacted service' {
            $commonCmdletParams.ImpactedService = 'Network Infrastructure'
            $result = New-WAFOutageObject @commonCmdletParams

            $expected.impactedService = ($commonCmdletParams.ImpactedService -join ', ')

            $result | Should -BeOfType [PSCustomObject]
            $result.Subscription | Should -BeExactly $expected.subscription
            $result.TrackingId | Should -BeExactly $expected.trackingId
            $result.Status | Should -BeExactly $expected.status
            $result.LastUpdateTime | Should -BeExactly $expected.lastUpdateTime
            $result.StartTime | Should -BeExactly $expected.startTime
            $result.EndTime | Should -BeExactly $expected.endTime
            $result.Level | Should -BeExactly $expected.level
            $result.Title | Should -BeExactly $expected.title
            $result.Summary | Should -BeExactly $expected.summary
            $result.Header | Should -BeExactly $expected.header
            $result.ImpactedService | Should -BeExactly $expected.impactedService
            $result.Description | Should -BeExactly $expected.description
        }

        It 'Should return an OutageObject with multiple impacted services' {
            $commonCmdletParams.ImpactedService = 'Network Infrastructure', 'Azure Database for MySQL', 'Automation'
            $result = New-WAFOutageObject @commonCmdletParams

            $expected.impactedService = ($commonCmdletParams.ImpactedService -join ', ')

            $result | Should -BeOfType [PSCustomObject]
            $result.Subscription | Should -BeExactly $expected.subscription
            $result.TrackingId | Should -BeExactly $expected.trackingId
            $result.Status | Should -BeExactly $expected.status
            $result.LastUpdateTime | Should -BeExactly $expected.lastUpdateTime
            $result.StartTime | Should -BeExactly $expected.startTime
            $result.EndTime | Should -BeExactly $expected.endTime
            $result.Level | Should -BeExactly $expected.level
            $result.Title | Should -BeExactly $expected.title
            $result.Summary | Should -BeExactly $expected.summary
            $result.Header | Should -BeExactly $expected.header
            $result.ImpactedService | Should -BeExactly $expected.impactedService
            $result.Description | Should -BeExactly $expected.description
        }
    }
}

Describe 'Get-WAFOutage' {
    Context 'When to get an OutageObject' {           
        BeforeAll {
            $moduleNameToInjectMock = 'outage'
            Mock Invoke-AzureRestAPI {
                return @{ Content = $restApiResponseContent }
            } -ModuleName $moduleNameToInjectMock -Verifiable
            
        }

        It 'Should return an OutageObject' {
            $restApiResponseFilePath = "$PSScriptRoot/../data/outage/restApiSingleResponseData.json"
            $restApiResponseContent = Get-Content $restApiResponseFilePath -Raw



            $subscriptionId = '11111111-1111-1111-1111-111111111111'

            $responseObject = ($restApiResponseContent | ConvertFrom-Json -Depth 15).value
            $expected = @{
                subscription    = $subscriptionId
                trackingId      = $responseObject.name
                status          = $responseObject.properties.status
                lastUpdateTime  = $responseObject.properties.lastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
                startTime       = $responseObject.properties.impactStartTime.ToString('yyyy-MM-dd HH:mm:ss')
                endTime         = $responseObject.properties.impactMitigationTime.ToString('yyyy-MM-dd HH:mm:ss')
                level           = $responseObject.properties.level
                title           = $responseObject.properties.title
                summary         = $responseObject.properties.summary
                header          = $responseObject.properties.header
                impactedService = $responseObject.properties.impact.impactedService -join ', '
                description     = $responseObject.properties.description
            }

            $result = Get-WAFOutage -SubscriptionIds $subscriptionId

            Should -InvokeVerifiable
            $result | Should -BeOfType [PSCustomObject]
            $result.Subscription | Should -BeExactly $expected.subscription
            $result.TrackingId | Should -BeExactly $expected.trackingId
            $result.Status | Should -BeExactly $expected.status
            $result.LastUpdateTime | Should -BeExactly $expected.lastUpdateTime
            $result.StartTime | Should -BeExactly $expected.startTime
            $result.EndTime | Should -BeExactly $expected.endTime
            $result.Level | Should -BeExactly $expected.level
            $result.Title | Should -BeExactly $expected.title
            $result.Summary | Should -BeExactly $expected.summary
            $result.Header | Should -BeExactly $expected.header
            $result.ImpactedService | Should -BeExactly $expected.impactedService
            $result.Description | Should -BeExactly $expected.description
        }

        It 'Should return multiple OutageObjects' {
            $restApiResponseFilePath = "$PSScriptRoot/../data/outage/restApiMultipleResponseData.json"
            $restApiResponseContent = Get-Content $restApiResponseFilePath -Raw

            Mock Invoke-AzureRestApi {
                return @{ Content = $restApiResponseContent }
            } -ModuleName $moduleNameToInjectMock -Verifiable

            $subscriptionId = '11111111-1111-1111-1111-111111111111'

            $responseObjects = ($restApiResponseContent | ConvertFrom-Json -Depth 15).value
            $expectedValues = foreach ($responseObject in $responseObjects) {
                @{
                    subscription    = $subscriptionId
                    trackingId      = $responseObject.name
                    status          = $responseObject.properties.status
                    lastUpdateTime  = $responseObject.properties.lastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
                    startTime       = $responseObject.properties.impactStartTime.ToString('yyyy-MM-dd HH:mm:ss')
                    endTime         = $responseObject.properties.impactMitigationTime.ToString('yyyy-MM-dd HH:mm:ss')
                    level           = $responseObject.properties.level
                    title           = $responseObject.properties.title
                    summary         = $responseObject.properties.summary
                    header          = $responseObject.properties.header
                    impactedService = $responseObject.properties.impact.impactedService -join ', '
                    description     = $responseObject.properties.description
                }
            }

            $results = Get-WAFOutage -SubscriptionId $subscriptionId

            Should -InvokeVerifiable
            $results.Length | Should -BeExactly $expectedValues.Length

            for ($i = 0; $i -lt $results.Length; $i++) {
                $result = $results[$i]
                $expected = $expectedValues[$i]

                $result | Should -BeOfType [PSCustomObject]
                $result.Subscription | Should -BeExactly $expected.subscription
                $result.TrackingId | Should -BeExactly $expected.trackingId
                $result.Status | Should -BeExactly $expected.status
                $result.LastUpdateTime | Should -BeExactly $expected.lastUpdateTime
                $result.StartTime | Should -BeExactly $expected.startTime
                $result.EndTime | Should -BeExactly $expected.endTime
                $result.Level | Should -BeExactly $expected.level
                $result.Title | Should -BeExactly $expected.title
                $result.Summary | Should -BeExactly $expected.summary
                $result.Header | Should -BeExactly $expected.header
                $result.ImpactedService | Should -BeExactly $expected.impactedService
                $result.Description | Should -BeExactly $expected.description
            }
        }
    }
}
