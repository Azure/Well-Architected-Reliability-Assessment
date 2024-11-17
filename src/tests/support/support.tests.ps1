BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/support/support.psm1"
    Import-Module -Name $modulePath -Force
    Import-Module -Name 'Az.ResourceGraph' -Force
}

Describe 'Get-WAFSupportTicket' {
    Context 'When to get SupportTicketObject' {
        BeforeAll {
            $moduleNameToInjectMock = 'support'
        }

        It 'Should return a SupportTicketObject' {
            $testDataFilePath = "$PSScriptRoot/../data/support/argQuerySingleResultData.json"
            $testData = Get-Content $testDataFilePath -Raw | ConvertFrom-Json -Depth 5

            Mock Search-AzGraph {
                return $testData
            } -ModuleName $moduleNameToInjectMock -Verifiable

            $expected = @{
                'Ticket ID'         = $testData.supportTicketId
                'Severity'          = $testData.severity
                'Status'            = $testData.status
                'Support Plan Type' = $testData.supportPlanType
                'Creation Date'     = $testData.createdDate.ToString('yyyy-MM-dd HH:mm:ss')
                'Modified Date'     = $testData.modifiedDate.ToString('yyyy-MM-dd HH:mm:ss')
                'Title'             = $testData.title
                'Related Resource'  = $testData.technicalTicketDetailsResourceId
            }

            $result = Get-WAFSupportTicket -SubscriptionId '11111111-1111-1111-1111-111111111111'

            Should -InvokeVerifiable
            $result | Should -BeOfType [PSCustomObject]
            $result.'Ticket ID' | Should -BeExactly $expected.'Ticket ID'
            $result.'Severity' | Should -BeExactly $expected.'Severity'
            $result.'Status' | Should -BeExactly $expected.'Status'
            $result.'Support Plan Type' | Should -BeExactly $expected.'Support Plan Type'
            $result.'Creation Date' | Should -BeExactly $expected.'Creation Date'
            $result.'Modified Date' | Should -BeExactly $expected.'Modified Date'
            $result.'Title' | Should -BeExactly $expected.'Title'
            $result.'Related Resource' | Should -BeExactly $expected.'Related Resource'
        }

        It 'Should return multiple SupportTicketObjects' {
            $testDataFilePath = "$PSScriptRoot/../data/support/argQueryMultipleResultData.json"
            $testDataArray = Get-Content $testDataFilePath -Raw | ConvertFrom-Json -Depth 5

            Mock Search-AzGraph {
                return $testDataArray
            } -ModuleName $moduleNameToInjectMock -Verifiable

            $expectedArray = foreach ($testData in $testDataArray) {
                @{
                    'Ticket ID'         = $testData.supportTicketId
                    'Severity'          = $testData.severity
                    'Status'            = $testData.status
                    'Support Plan Type' = $testData.supportPlanType
                    'Creation Date'     = $testData.createdDate.ToString('yyyy-MM-dd HH:mm:ss')
                    'Modified Date'     = $testData.modifiedDate.ToString('yyyy-MM-dd HH:mm:ss')
                    'Title'             = $testData.title
                    'Related Resource'  = $testData.technicalTicketDetailsResourceId
                }
            }
            
            $results = Get-WAFSupportTicket -SubscriptionId '11111111-1111-1111-1111-111111111111'

            Should -InvokeVerifiable
            $results.Length | Should -BeExactly $expectedArray.Length

            for ($i = 0; $i -lt $results.Length; $i++) {
                $result = $results[$i]
                $expected = $expectedArray[$i]

                $result | Should -BeOfType [PSCustomObject]
                $result.'Ticket ID' | Should -BeExactly $expected.'Ticket ID'
                $result.'Severity' | Should -BeExactly $expected.'Severity'
                $result.'Status' | Should -BeExactly $expected.'Status'
                $result.'Support Plan Type' | Should -BeExactly $expected.'Support Plan Type'
                $result.'Creation Date' | Should -BeExactly $expected.'Creation Date'
                $result.'Modified Date' | Should -BeExactly $expected.'Modified Date'
                $result.'Title' | Should -BeExactly $expected.'Title'
                $result.'Related Resource' | Should -BeExactly $expected.'Related Resource'
            }
        }
    }
}

Describe 'New-WAFSupportTicketObject' {
    Context 'When to get a SupportTicketObject' {
        BeforeEach {
            $testData = @{
                SupportTicketId                  = '1234567890123456'
                Severity                         = 'Moderate'
                Status                           = 'Open'
                SupportPlanType                  = 'Unified Enterprise'
                CreatedDate                      = Get-Date -Year 2024 -Month 1 -Day 2 -Hour 3 -Minute 4 -Second 5
                ModifiedDate                     = Get-Date -Year 2024 -Month 6 -Day 7 -Hour 8 -Minute 9 -Second 10
                Title                            = 'Test Support Case'
                TechnicalTicketDetailsResourceId = $null  # Set per test case
            }

            $expected = @{
                'Ticket ID'         = $testData.SupportTicketId
                'Severity'          = $testData.Severity
                'Status'            = $testData.Status
                'Support Plan Type' = $testData.SupportPlanType
                'Creation Date'     = $testData.CreatedDate.ToString('yyyy-MM-dd HH:mm:ss')
                'Modified Date'     = $testData.ModifiedDate.ToString('yyyy-MM-dd HH:mm:ss')
                'Title'             = $testData.Title
                'Related Resource'  = $null  # Set per test case
            }

            $cmdletParams = @{
                SupportTicketId                  = $testData.SupportTicketId
                Severity                         = $testData.Severity
                Status                           = $testData.Status
                SupportPlanType                  = $testData.SupportPlanType
                CreatedDate                      = $testData.CreatedDate
                ModifiedDate                     = $testData.ModifiedDate
                Title                            = $testData.Title
                TechnicalTicketDetailsResourceId = $null  # Set per test case
            }
        }

         It 'Should return a SupportTicketObject with resource ID' {
            $resourceId = '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/test-rg/providers/Resource.Provider/resourceType/resource'
            $expected.'Related Resource' = $resourceId
            $cmdletParams.TechnicalTicketDetailsResourceId = $resourceId

            $result = New-WAFSupportTicketObject @cmdletParams

            $result | Should -BeOfType [PSCustomObject]
            $result.'Ticket ID' | Should -BeExactly $expected.'Ticket ID'
            $result.'Severity' | Should -BeExactly $expected.'Severity'
            $result.'Status' | Should -BeExactly $expected.'Status'
            $result.'Support Plan Type' | Should -BeExactly $expected.'Support Plan Type'
            $result.'Creation Date' | Should -BeExactly $expected.'Creation Date'
            $result.'Modified Date' | Should -BeExactly $expected.'Modified Date'
            $result.'Title' | Should -BeExactly $expected.'Title'
            $result.'Related Resource' | Should -BeExactly $expected.'Related Resource'
        }

        It 'Should return a SupportTicketObject without resource ID' {
            $resourceId = ''  # Empty string
            $expected.'Related Resource' = $resourceId
            $cmdletParams.TechnicalTicketDetailsResourceId = $resourceId

            $result = New-WAFSupportTicketObject @cmdletParams

            $result | Should -BeOfType [PSCustomObject]
            $result.'Ticket ID' | Should -BeExactly $expected.'Ticket ID'
            $result.'Severity' | Should -BeExactly $expected.'Severity'
            $result.'Status' | Should -BeExactly $expected.'Status'
            $result.'Support Plan Type' | Should -BeExactly $expected.'Support Plan Type'
            $result.'Creation Date' | Should -BeExactly $expected.'Creation Date'
            $result.'Modified Date' | Should -BeExactly $expected.'Modified Date'
            $result.'Title' | Should -BeExactly $expected.'Title'
            $result.'Related Resource' | Should -BeExactly $expected.'Related Resource'
        }
    }
}
