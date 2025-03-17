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
