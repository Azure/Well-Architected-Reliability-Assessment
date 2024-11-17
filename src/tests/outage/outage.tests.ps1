BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/outage/outage.psm1"
    Import-Module -Name $modulePath -Force
    Import-Module -Name 'Az.ResourceGraph' -Force
}

Describe 'Get-WAFOutage' {
    Context 'When to get an OutageObject' {
        BeforeAll {
            $moduleNameToInjectMock = 'outage'
        }

        It 'Should return an OutageObject' {
            $testDataFilePath = "$PSScriptRoot/../data/outage/argQuerySingleResultData.json"
            $testData = Get-Content $testDataFilePath -Raw | ConvertFrom-Json -Depth 5

            Mock Search-AzGraph {
                return $testData
            } -ModuleName $moduleNameToInjectMock -Verifiable

            $expected = @{
                subscription    = $testData.subscriptionId
                trackingId      = $testData.trackingId
                status          = $testData.status
                lastUpdateTime  = $testData.lastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
                startTime       = $testData.impactStartTime.ToString('yyyy-MM-dd HH:mm:ss')
                endTime         = $testData.impactMitigationTime.ToString('yyyy-MM-dd HH:mm:ss')
                level           = $testData.level
                title           = $testData.title
                summary         = $testData.summary
                header          = $testData.header
                impactedService = $testData.impactedServices -join ', '
                description     = $testData.summary  # Use the summary as the description, it's by design.
            }

            $result = Get-WAFOutage -SubscriptionId '11111111-1111-1111-1111-111111111111'

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
            $testDataFilePath = "$PSScriptRoot/../data/outage/argQueryMultipleResultData.json"
            $testDataArray = Get-Content $testDataFilePath -Raw | ConvertFrom-Json -Depth 5

            Mock Search-AzGraph {
                return $testDataArray
            } -ModuleName $moduleNameToInjectMock -Verifiable

            $expectedArray = foreach ($testData in $testDataArray) {
                @{
                    subscription    = $testData.subscriptionId
                    trackingId      = $testData.trackingId
                    status          = $testData.status
                    lastUpdateTime  = $testData.lastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
                    startTime       = $testData.impactStartTime.ToString('yyyy-MM-dd HH:mm:ss')
                    endTime         = $testData.impactMitigationTime.ToString('yyyy-MM-dd HH:mm:ss')
                    level           = $testData.level
                    title           = $testData.title
                    summary         = $testData.summary
                    header          = $testData.header
                    impactedService = $testData.impactedServices -join ', '
                    description     = $testData.summary  # Use the summary as the description, it's by design.
                }
            }

            $results = Get-WAFOutage -SubscriptionId '11111111-1111-1111-1111-111111111111'

            Should -InvokeVerifiable
            $results.Length | Should -BeExactly $expectedArray.Length

            for ($i = 0; $i -lt $results.Length; $i++) {
                $result = $results[$i]
                $expected = $expectedArray[$i]

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

Describe 'New-WAFOutageObject' {
    Context 'When to get an OutageObject' {
        BeforeEach {
            $testData = @{
                SubscriptionId  = '11111111-1111-1111-1111-111111111111'
                TrackingId      = 'XXXX-XXX'
                Status          = 'Active'
                LastUpdateTime  = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                StartTime       = Get-Date -Year 2024 -Month 6 -Day 7 -Hour 8 -Minute 9 -Second 10
                EndTime         = Get-Date -Year 2024 -Month 11 -Day 12 -Hour 13 -Minute 14 -Second 15
                Level           = 'Warning'
                Title           = 'Mitigated - Storage Metrics UI Regression Impacting Non-Classic Storage Accounts in Azure Monitor'
                Summary         = '<p><strong>What happened?</strong></p>'
                Header          = 'Your service might have been impacted by an Azure service issue'
                Description     = '* Description *'  # We don't care the description.
            }

            $expected = @{
                subscription    = $testData.SubscriptionId
                trackingId      = $testData.TrackingId
                status          = $testData.Status
                lastUpdateTime  = $testData.LastUpdateTime.ToString('yyyy-MM-dd HH:mm:ss')
                startTime       = $testData.StartTime.ToString('yyyy-MM-dd HH:mm:ss')
                endTime         = $testData.EndTime.ToString('yyyy-MM-dd HH:mm:ss')
                level           = $testData.Level
                title           = $testData.Title
                summary         = $testData.Summary
                header          = $testData.Header
                description     = $testData.Summary  # Use the summary as the description, it's by design.
            }

            $cmdletParams = @{
                SubscriptionId  = $testData.SubscriptionId
                TrackingId      = $testData.TrackingId
                Status          = $testData.Status
                LastUpdateTime  = $testData.LastUpdateTime
                StartTime       = $testData.StartTime
                EndTime         = $testData.EndTime
                Level           = $testData.Level
                Title           = $testData.Title
                Summary         = $testData.Summary
                Header          = $testData.Header
                Description     = $testData.Summary  # Use the summary as the description, it's by design.
            }
        }

        It 'Should return an OutageObject with a single impacted service' {
            $impactedService = 'Network Infrastructure'
            $expected.impactedService = $impactedService -join ', '
            $cmdletParams.ImpactedService = $impactedService

            $result = New-WAFOutageObject @cmdletParams

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
            $impactedServices = 'Network Infrastructure', 'Azure Database for MySQL', 'Automation'
            $expected.impactedService = $impactedServices -join ', '
            $cmdletParams.ImpactedService = $impactedServices

            $result = New-WAFOutageObject @cmdletParams

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
