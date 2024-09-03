function Get-WAFOutage {
    Param($BaseURL,$Subid)

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