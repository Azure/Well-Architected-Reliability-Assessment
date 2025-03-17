<#
.SYNOPSIS
    Retrieves recent service tickets for a given Azure subscription.

.DESCRIPTION
    The Get-WAFSupportTicket function queries the Azure Resource Graph to retrieve recent service tickets for a specified Azure subscription. It filters the service tickets to include only those that have created in the last three months.

.PARAMETER SubscriptionIds
    The subscription ID for the Azure subscription to retrieve service tickets.

.OUTPUTS
    Returns a list of service tickets, including the name and properties of each tickets.

.EXAMPLE
    PS> $serviceTiketObjects = Get-WAFSupportTicket -SubscriptionIds '11111111-1111-1111-1111-111111111111'

    This example retrieves the recent service tickets for the specified Azure subscription.

.NOTES
    Author: Takeshi Katano
    Date: 2024-11-08
#>
function Get-WAFSupportTicket {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-WAFIsGuid -StringGuid $_ })]
        [string[]] $SubscriptionIds
    )

    $argQuery = @'
SupportResources
| where type =~ "Microsoft.Support/supportTickets"
| where properties.Severity !~ "Minimal"  // Exclude severity C
| extend
    createdDateAsDateTime  = todatetime(properties.CreatedDate),   // UTC
    modifiedDateAsDateTime = todatetime(properties.ModifiedDate)   // UTC
| where createdDateAsDateTime >= datetime_add("Month", -3, now())  // Last 3 months (not 90 days)
| project
    supportTicketId                  = properties.SupportTicketId,
    severity                         = properties.Severity,
    status                           = properties.Status,
    supportPlanType                  = properties.SupportPlanType,
    createdDate                      = createdDateAsDateTime,
    modifiedDate                     = modifiedDateAsDateTime,
    title                            = properties.Title,
    technicalTicketDetailsResourceId = iif(isnull(properties.TechnicalTicketDetails.ResourceId), "", properties.TechnicalTicketDetails.ResourceId)
| order by createdDate desc
'@

    $supportTickets = Invoke-WAFQuery -SubscriptionIds $SubscriptionIds -Query $argQuery

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
