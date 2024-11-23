using module ../utils/utils.psd1

<#
.SYNOPSIS
    Retrieves recent support tickets.

.DESCRIPTION
    This module contains functions related to the capturing and collecting to recent service tickets.
    It includes the following functions:
    - Get-WAFSupportTicket
    - New-WAFSupportTicketObject

.EXAMPLE
    PS> $serviceTiketObjects = Get-WAFSupportTicket -SubscriptionIds '11111111-1111-1111-1111-111111111111'

.NOTES
    Author: Takeshi Katano
    Date: 2024-11-08
#>

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
        [ValidatePattern('^[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}$')]
        [string[]] $SubscriptionIds
    )

    Import-Module -Name 'Az.ResourceGraph'

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

<#
.SYNOPSIS
    Creates a service ticket object.

.DESCRIPTION
    The New-WAFSupportTicketObject function creates a service ticket based on the specified parameters.

.PARAMETER SupportTicketId
    The ID of the support ticket. It's usually sixteen digits of number.

.PARAMETER Severity
    The severity of the support ticket such as Minimal, Moderate, etc.

.PARAMETER Status
    The status of the support ticket. It's usually Open or Closed.

.PARAMETER SupportPlanType
    The support plan type of the support ticket such as Unified Enterprise, etc.

.PARAMETER CreatedDate
    The created date of the support ticket.

.PARAMETER ModifiedDate
    The modified date of the support ticket.

.PARAMETER Title
    The title of the support ticket.

.PARAMETER TechnicalTicketDetailsResourceId
    The resource ID of the related Azure resource to the support ticket if it's available.

.OUTPUTS
    Returns a SupportTicketObject as a PSCustomObject.

.EXAMPLE
    PS> $serviceTiketObject = New-WAFSupportTicketObject -SupportTicketId '0123456789012345' -Severity 'Moderate' -Status 'Open' -SupportPlanType 'Unified Enterprise' -CreatedDate $createdDate -ModifiedDate $modifiedDate -Title $title -TechnicalTicketDetailsResourceId $resourceId

.NOTES
    Author: Takeshi Katano
    Date: 2024-11-08
#>
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
