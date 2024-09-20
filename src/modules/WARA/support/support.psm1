function Get-WAFSupportTicket {
    Param($BaseURL,$Subid)

    $Token = Get-AzAccessToken -AsSecureString -InformationAction SilentlyContinue -WarningAction SilentlyContinue

    $TokenData = $Token.Token | ConvertFrom-SecureString -AsPlainText

    $DateCore = (Get-Date).AddMonths(-3)

    $header = @{
    'Authorization' = 'Bearer ' + $TokenData
    }

    $supurl = ('https://' + $BaseURL + '/subscriptions/' + $Subid + '/providers/Microsoft.Support/supportTickets?api-version=2020-04-01')
    $SupTickets = Invoke-RestMethod -Uri $supurl -Headers $header -Method GET
    $Tickets = $SupTickets.value | Where-Object { $_.properties.severity -ne 'Minimal' -and $_.properties.createdDate -gt $DateCore } | Select-Object -Property name, properties

    $SupportTickets = foreach ($Ticket in $Tickets) {
        $tmp = @{
            'Ticket ID'         = [string]$Ticket.properties.supportTicketId;
            'Severity'          = [string]$Ticket.properties.severity;
            'Status'            = [string]$Ticket.properties.status;
            'Support Plan Type' = [string]$Ticket.properties.supportPlanType;
            'Creation Date'     = [string]$Ticket.properties.createdDate;
            'Modified Date'     = [string]$Ticket.properties.modifiedDate;
            'Title'             = [string]$Ticket.properties.title;
            'Related Resource'  = [string]$Ticket.properties.technicalTicketDetails.resourceId
        }
        $tmp
    }
    return $SupportTickets
}