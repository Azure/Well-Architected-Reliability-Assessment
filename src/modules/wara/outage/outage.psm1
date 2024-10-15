<#
.SYNOPSIS
Retrieves recent outage events for a given Azure subscription.

.DESCRIPTION
The Get-WAFOutage function queries the Microsoft Resource Health API to retrieve recent outage events for a specified Azure subscription. It filters the events to include only those that have occurred in the last three months and sorts them by event level and status.

.PARAMETER BaseURL
The base URL for the Microsoft Resource Health API.

.PARAMETER Subid
The subscription ID for the Azure subscription.

.OUTPUTS
Returns a list of outage events, including the name and properties of each event.

.EXAMPLE
PS> $outages = Get-WAFOutage -BaseURL "management.azure.com" -Subid "your-subscription-id"
This example retrieves the recent outage events for the specified Azure subscription.

.NOTES
This function requires the Az.Accounts module to be installed and imported.
#>
function Get-WAFOutage {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$BaseURL,

        [Parameter(Mandatory = $true)]
        [string]$Subid
    )

    $Token = Get-AzAccessToken -AsSecureString -InformationAction SilentlyContinue -WarningAction SilentlyContinue

    $TokenData = $Token.Token | ConvertFrom-SecureString -AsPlainText

    $Date = (Get-Date).AddMonths(-24)
    $DateOutages = (Get-Date).AddMonths(-3)
    $Date = $Date.ToString('MM/dd/yyyy')

    $header = @{
        'Authorization' = 'Bearer ' + $TokenData
    }

    $url = ('https://' + $BaseURL + '/subscriptions/' + $Subid + '/providers/Microsoft.ResourceHealth/events?api-version=2022-10-01&queryStartTime=' + $Date)
    $Outages = Invoke-RestMethod -Uri $url -Headers $header -Method GET
    $Outageslist = $Outages.value | Where-Object { $_.properties.impactStartTime -gt $DateOutages } | Sort-Object @{Expression = 'properties.eventlevel'; Descending = $false }, @{Expression = 'properties.status'; Descending = $false } | Select-Object -Property name, properties -First 15

    return $Outageslist
}