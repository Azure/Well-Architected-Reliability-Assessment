BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/utils/utils.psd1"
    Import-Module -Name $modulePath -Force
    Import-Module -Name 'Az.Accounts' -Force
}

Describe 'Get-AzureRestMethodUriPath' {
    Context 'When to get an Azure REST API URI path' {
        BeforeEach {
            $commonCmdletParams = @{
                SubscriptionId       = '11111111-1111-1111-1111-111111111111'
                ResourceProviderName = 'Resource.Provider'
                ResourceType         = 'resourceType'
                ApiVersion           = '0000-00-00'
            }
        }

        It 'Should return the path that does contains resource group' {
            $commonCmdletParams.ResourceGroupName = 'test-rg'
            $commonCmdletParams.Name = 'resource1'
            $result = Get-AzureRestMethodUriPath @commonCmdletParams

            $expected = '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/test-rg/providers/Resource.Provider/resourceType/resource1?api-version=0000-00-00'

            $result | Should -BeExactly $expected
        }

        It 'Should return the path that does contains resource group with query string' {
            $commonCmdletParams.ResourceGroupName = 'test-rg'
            $commonCmdletParams.Name = 'resource1'
            $commonCmdletParams.QueryString = 'test=test'
            $result = Get-AzureRestMethodUriPath @commonCmdletParams

            $expected = '/subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/test-rg/providers/Resource.Provider/resourceType/resource1?api-version=0000-00-00&test=test'

            $result | Should -BeExactly $expected
        }

        It 'Should return the path that does not contains resource group' {
            $result = Get-AzureRestMethodUriPath @commonCmdletParams

            $expected = '/subscriptions/11111111-1111-1111-1111-111111111111/providers/Resource.Provider/resourceType?api-version=0000-00-00'

            $result | Should -BeExactly $expected
        }

        It 'Should return the path that does not contains resource group with query string' {
            $commonCmdletParams.QueryString = 'test=test'
            $result = Get-AzureRestMethodUriPath @commonCmdletParams

            $expected = '/subscriptions/11111111-1111-1111-1111-111111111111/providers/Resource.Provider/resourceType?api-version=0000-00-00&test=test'

            $result | Should -BeExactly $expected
        }
    }
}
Describe 'Invoke-AzureRestApi' {
    BeforeAll {
        $expected = 'JsonText'

        Mock Invoke-AzRestMethod {
            return @{ Content = $expected }
        } -ModuleName 'utils' -Verifiable
    }

    Context 'When to invoke an Azure REST API with a path WITH resource group' {
        BeforeEach {
            $commonCmdletParams = @{
                Method               = 'GET'
                SubscriptionId       = '11111111-1111-1111-1111-111111111111'
                ResourceGroupName    = 'test-rg'
                ResourceProviderName = 'Resource.Provider'
                ResourceType         = 'resourceType'
                Name                 = 'resource1'
                ApiVersion           = '0000-00-00'
            }
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API' {
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API with query string' {
            $commonCmdletParams.QueryString = 'test=test'
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API with request body' {
            $commonCmdletParams.RequestBody = 'test'
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API with query string and request body' {
            $commonCmdletParams.QueryString = 'test=test'
            $commonCmdletParams.RequestBody = 'test'
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }
    }
    
    Context 'When to invoke an Azure REST API with a path WITHOUT resource group' {
        BeforeEach {
            $commonCmdletParams = @{
                Method               = 'GET'
                SubscriptionId       = '11111111-1111-1111-1111-111111111111'
                ResourceProviderName = 'Resource.Provider'
                ResourceType         = 'resourceType'
                ApiVersion           = '0000-00-00'
            }
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API' {
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API with query string' {
            $commonCmdletParams.QueryString = 'test=test'
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API with request body' {
            $commonCmdletParams.RequestBody = 'test'
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }

        It 'Should call Get-AzureRestMethodUriPath and Invoke-AzRestMethod then return the response from the Azure REST API with query string and request body' {
            $commonCmdletParams.QueryString = 'test=test'
            $commonCmdletParams.RequestBody = 'test'
            $result = Invoke-AzureRestApi @commonCmdletParams

            Should -InvokeVerifiable
            $result.Content | Should -BeExactly $expected
        }
    }
}