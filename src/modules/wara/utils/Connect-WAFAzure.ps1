<#
.SYNOPSIS
    Connects to an Azure tenant.

.DESCRIPTION
    The Connect-WAFAzure function connects to an Azure tenant using the provided Tenant ID and Subscription IDs.

.PARAMETER TenantID
    The Tenant ID to connect to.

.PARAMETER SubscriptionIds
    An array of Subscription IDs to scope the connection.

.PARAMETER AzureEnvironment
    The Azure environment to connect to. Defaults to 'AzureCloud'.

.OUTPUTS
    None.

.EXAMPLE
    PS> Connect-WAFAzure -TenantID "your-tenant-id" -SubscriptionIds @("sub1", "sub2") -AzureEnvironment "AzureCloud"
#>
function Connect-WAFAzure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [GUID] $TenantID,

        [Parameter(Mandatory = $false)]
        [ValidateSet('AzureCloud', 'AzureChinaCloud', 'AzureGermanCloud', 'AzureUSGovernment')]
        [string] $AzureEnvironment = 'AzureCloud'
    )

    # Connect To Azure Tenant
    if ((Get-AzContext).Tenant.Id -ne $TenantID -or (Get-AzContext).Environment.Name -ne $AzureEnvironment) {
        Write-Debug "Connecting to Azure Tenant with Tenant ID: $TenantID and Azure Environment: $AzureEnvironment"
        Connect-AzAccount -Tenant $TenantID -WarningAction SilentlyContinue -Environment $AzureEnvironment | Out-Null
    }
}
