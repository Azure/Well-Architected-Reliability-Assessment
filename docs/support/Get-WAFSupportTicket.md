---
external help file: support-help.xml
Module Name: support
online version:
schema: 2.0.0
---

# Get-WAFSupportTicket

## SYNOPSIS

Retrieves recent service tickets for a given Azure subscription.

## SYNTAX

```powershell
Get-WAFSupportTicket [-SubscriptionIds] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

The Get-WAFSupportTicket function queries the Azure Resource Graph to retrieve recent service tickets for a specified Azure subscription. It filters the service tickets to include only those that have created in the last three months.

## EXAMPLES

### Example 1

```powershell
PS> $serviceTiketObjects = Get-WAFSupportTicket -SubscriptionIds '11111111-1111-1111-1111-111111111111'
```

This example retrieves the recent service tickets for the specified Azure subscription.

## PARAMETERS

### -SubscriptionIds

The subscription ID for the Azure subscription to retrieve service tickets.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

Returns a list of service tickets, including the name and properties of each tickets.

## NOTES

Author: Takeshi Katano
Date: 2024-11-08

## RELATED LINKS
