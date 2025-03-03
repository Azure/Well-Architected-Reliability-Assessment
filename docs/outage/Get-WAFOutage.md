---
external help file: outage-help.xml
Module Name: outage
online version:
schema: 2.0.0
---

# Get-WAFOutage

## SYNOPSIS

Retrieves recent outage events for a given Azure subscription.

## SYNTAX

```powershell
Get-WAFOutage [-SubscriptionIds] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

The Get-WAFOutage function queries the Microsoft Resource Health API to retrieve recent outage events for a specified Azure subscription. It filters the events to include only those that have updated in the last three months.

## EXAMPLES

### Example 1

```powershell
PS C:\> $outageObjects = Get-WAFOutage -SubscriptionIds '11111111-1111-1111-1111-111111111111'
```

This example retrieves the recent outage events for the specified Azure subscription.

## PARAMETERS

### -SubscriptionIds

The subscription ID for the Azure subscription to retrieve outage events.

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

Returns a list of outage events, including the name and properties of each event.

## NOTES

Author: Takeshi Katano
Date: 2024-10-23

## RELATED LINKS
