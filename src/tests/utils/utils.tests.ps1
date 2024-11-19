BeforeAll {
    $modulePath = "$PSScriptRoot/../../modules/wara/utils/utils.psd1"
    Import-Module -Name $modulePath -Force
    Import-Module -Name 'Az.Accounts'
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

Describe Import-WAFConfigFileData {
    BeforeEach {
        $TestConfigFile1 = "$PSScriptRoot/../data/utils/testconfig1.txt"

        $result = Import-WAFConfigFileData $TestConfigFile1


        $expectedTenantId = "12121212-1212-1212-1212-121212121212"
        $expectedSubscriptionIds = @(
            "/subscriptions/0000000-0000-0000-0000-000000000000"
        )
        $expectedResourceGroups = @(
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-01",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-02",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-03",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-04",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-05",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-06",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-07",
            "/subscriptions/1111111-1111-1111-1111-111111111111/resourceGroups/RG-08"
        )
        $expectedTags = @(
            "env||environment=~preprod",
            "app||application!~app1||app2"
        )
    }

    Context 'Import a WAF config file with valid and invalid data' {
        It 'Should return the correct content of the WAF config file' {
            # Call the function with the test configuration file
            
            # Validate the results
            $result.tenantid | Should -BeExactly $expectedTenantId
            $result.bad1 | Should -BeNullOrEmpty
            $result.subscriptionIds | Should -BeExactly $expectedSubscriptionIds
            $result.resourcegroups | Should -Be $expectedResourceGroups
            $result.tags | Should -BeExactly $expectedTags
        }
    }  
}
Describe 'Connect-WAFAzure' {
    Context 'When TenantID is provided' {

        BeforeEach {
            Mock Connect-AzAccount { @{ } } -Verifiable -ModuleName utils
            Mock Get-AzContext { return $null } -Verifiable -ModuleName utils
        }
        It 'Should call Connect-AzAccount with the correct parameters' {
            $TenantID = [Guid]::NewGuid()
            $AzureEnvironment = 'AzureCloud'

            Connect-WAFAzure -TenantID $TenantID -AzureEnvironment $AzureEnvironment

            # Verify that Connect-AzAccount was called
            Should -InvokeVerifiable
        }

        It 'Should not call Connect-AzAccount if Get-AzContext returns a context' {
            Mock Get-AzContext { return $true } -ModuleName utils
            Mock Connect-AzAccount { @{ } } -Verifiable -ModuleName utils

            $tenantId = [Guid]::NewGuid()

            Connect-WAFAzure -TenantID $tenantId

            # Verify that Connect-AzAccount was not called
            Should -Not -InvokeVerifiable 
        }
    }
}

Describe 'Test-WAFTagPattern' {
    Context 'When given a valid tag pattern' {
        It 'Should return true' {
            $tagPattern = "env||environment=~preprod"
            $result = Test-WAFTagPattern $tagPattern
            $result | Should -Be $true
        }
    }
    Context 'When given an invalid tag pattern' {
        It 'Should throw the exception' {
            $tagPattern = "env||environment~preprod"
            {Test-WAFTagPattern $tagPattern} | Should -Throw 
        }
    }
}

Describe 'Test-WAFResourceGroupId'{
    Context 'When given a valid resource group id' {
        It 'Should return true with a valid resource group id' {
            $resourceGroupId = "/subscriptions/$((new-guid).guid)/resourceGroups/RG-01"
            $result = Test-WAFResourceGroupId $resourceGroupId
            $result | Should -Be $true
        }
        It 'Should return true when the resource group id contains a trailing slash' {
            $resourceGroupId = "/subscriptions/$((new-guid).guid)/resourceGroups/RG-01/"
            $result = Test-WAFResourceGroupId $resourceGroupId
            $result | Should -Be $true
        }
    }
    Context 'When given an invalid resource group id' {
        It 'Should throw the exception with a bad GUID' {
            $resourceGroupId = "/subscriptions/$((new-guid).guid[1..-1])/resourceGroups/RG-01/"
            {Test-WAFResourceGroupId $resourceGroupId} | Should -Throw 
        }
        It 'Should throw the exception with a bad resourceGroups typo - missing s' {
            $resourceGroupId = "/subscriptions/$((new-guid).guid)/resourceGroup/RG-01/"
            {Test-WAFResourceGroupId $resourceGroupId} | Should -Throw 
        }
        It 'Should throw the exception with a bad subscription typo - missing s' {
            $resourceGroupId = "/subscription/$((new-guid).guid)/resourceGroups/RG-01/"
            {Test-WAFResourceGroupId $resourceGroupId} | Should -Throw 
        }
        It 'Should throw the exception when missing the leading slash' {
            $resourceGroupId = "subscriptions/$((new-guid).guid)/resourceGroups/RG-01"
            {Test-WAFResourceGroupId $resourceGroupId} | Should -Throw 
        }
    }
}

Describe 'Test-WAFSubscriptionId'{
    Context 'When given a valid subscription id' {
        It 'Should return true with a valid subscription id' {
            $subscriptionId = "/subscriptions/$((new-guid).guid)"
            $result = Test-WAFSubscriptionId $subscriptionId
            $result | Should -Be $true
        }
        It 'Should return true when the subscription id contains a trailing slash' {
            $subscriptionId = "/subscriptions/$((new-guid).guid)/"
            $result = Test-WAFSubscriptionId $subscriptionId
            $result | Should -Be $true
        }
    }
    Context 'When given an invalid subscription id' {
        It 'Should throw the exception with a bad GUID' {
            $subscriptionId = "/subscriptions/$((new-guid).guid[1..-1])/"
            {Test-WAFSubscriptionId $subscriptionId} | Should -Throw 
        }
        It 'Should throw the exception with a bad subscription typo - missing s' {
            $subscriptionId = "/subscription/$((new-guid).guid)/"
            {Test-WAFSubscriptionId $subscriptionId} | Should -Throw 
        }
        It 'Should throw the exception when missing the leading slash' {
            $subscriptionId = "subscriptions/$((new-guid).guid)"
            {Test-WAFSubscriptionId $subscriptionId} | Should -Throw 
        }
    }
}

Describe 'Test-WAFIsGuid'{
    Context 'When given a valid GUID' {
        It 'Should return true with a valid GUID' {
            $guid = [Guid]::NewGuid()
            $result = Test-WAFIsGuid $guid
            $result | Should -Be $true
        }
    }
    Context 'When given an invalid GUID' {
        It 'Should throw the exception with a bad GUID' {
            $guid = [Guid]::NewGuid().guid[1..-1]
            {Test-WAFIsGuid $guid} | Should -Throw 
        }
    }
}
