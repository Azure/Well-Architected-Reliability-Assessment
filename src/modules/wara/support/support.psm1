function Get-WAFSupportTicket {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string] $SubscriptionId
    )

    $argQuery = @'
SupportResources
| where type =~ "Microsoft.Support/supportTickets"
| where properties.Severity !~ "Minimal"  // Exclude severity C
| extend
    createdDateAsDateTime = todatetime(properties.CreatedDate),   // UTC
    modifiedDateAsDateTime = todatetime(properties.ModifiedDate)  // UTC
| where createdDateAsDateTime > datetime_add("Month", -3, now())  // Last 3 months (not 90 days)
| order by createdDateAsDateTime desc
| project
    supportTicketId = properties.SupportTicketId,
    severity = properties.Severity,
    status = properties.Status,
    supportPlanType = properties.SupportPlanType,
    createdDate = createdDateAsDateTime,
    modifiedDate = modifiedDateAsDateTime,
    title = properties.Title,
    technicalTicketDetailsResourceId = iif(isnull(properties.TechnicalTicketDetails.ResourceId), "", properties.TechnicalTicketDetails.ResourceId)
'@

    $supportTickets = Search-AzGraph -Subscription $SubscriptionId -First 1000 -Query $argQuery

    $supportTicketObjects = foreach ($supportTicket in $supportTickets) {
        $cmdletParams = @{
            SupportTicketId                  = $supportTicket.supportTicketId
            Severity                         = $supportTicket.severity
            Status                           = $supportTicket.status
            SupportPlanType                  = $supportTicket.supportPlanType
            CreatedDate                      = $supportTicket.createdDate
            ModifiedDate                     = $supportTicket.modifiedDate
            Title                            = $supportTicket.title
            TechnicalTicketDetailsResourceId = $supportTicket.technicalTicketDetailsResourceId
        }
        New-WAFSupportTicketObject @cmdletParams
    }

    return $supportTicketObjects
}

function New-WAFSupportTicketObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $SupportTicketId,

        [Parameter(Mandatory = $true)]
        [string] $Severity,

        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [string] $SupportPlanType,

        [Parameter(Mandatory = $true)]
        [datetime] $CreatedDate,

        [Parameter(Mandatory = $true)]
        [datetime] $ModifiedDate,

        [Parameter(Mandatory = $true)]
        [string] $Title,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $TechnicalTicketDetailsResourceId
    )

    return [PSCustomObject] @{
        'Ticket ID'         = $SupportTicketId
        'Severity'          = $Severity
        'Status'            = $Status
        'Support Plan Type' = $SupportPlanType
        'Creation Date'     = $CreatedDate.ToString('yyyy-MM-dd HH:mm:ss')
        'Modified Date'     = $ModifiedDate.ToString('yyyy-MM-dd HH:mm:ss')
        'Title'             = $Title
        'Related Resource'  = $TechnicalTicketDetailsResourceId
    }
}
