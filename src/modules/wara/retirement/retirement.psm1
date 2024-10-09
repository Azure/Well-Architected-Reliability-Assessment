function Get-WAFResourceRetirement {
    Param($BaseURL,$Subid)

    $Token = Get-AzAccessToken -AsSecureString -InformationAction SilentlyContinue -WarningAction SilentlyContinue

    $TokenData = $Token.Token | ConvertFrom-SecureString -AsPlainText

    $Date = (Get-Date).AddMonths(-24)
    $Date = $Date.ToString('MM/dd/yyyy')

    $header = @{
    'Authorization' = 'Bearer ' + $TokenData
    }

    $url = ('https://' + $BaseURL + '/subscriptions/' + $Subid + '/providers/Microsoft.ResourceHealth/events?api-version=2022-10-01&queryStartTime=' + $Date)
    $Outages = Invoke-RestMethod -Uri $url -Headers $header -Method GET
    $RetiredOutages += $Outages.value | Sort-Object @{Expression = 'properties.eventlevel'; Descending = $false }, @{Expression = 'properties.status'; Descending = $false } | Select-Object -Property name, properties

    $retquery = "servicehealthresources | where properties.EventSubType contains 'Retirement' | order by id"
    $queryResults = Invoke-WAFQuery -Query $retquery -subscriptionId $Subid

    $AllRetirements = foreach ($row in $queryResults) {
        $OutagesRetired = $RetiredOutages | Where-Object { $_.name -eq $row.properties.TrackingId }

        $result = [PSCustomObject]@{
            Subscription    = [string]$Subid
            TrackingId      = [string]$row.properties.TrackingId
            Status          = [string]$row.Properties.Status
            LastUpdateTime  = [string]$OutagesRetired.properties.lastUpdateTime
            Endtime         = [string]$OutagesRetired.properties.impactMitigationTime
            Level           = [string]$row.properties.Level
            Title           = [string]$row.properties.Title
            Summary         = [string]$row.properties.Summary
            Header          = [string]$row.properties.Header
            ImpactedService = [string]$row.properties.Impact.ImpactedService
            Description     = [string]$OutagesRetired.properties.description
        }
        $result
    }
    return $AllRetirements
}