---
external help file: retirement-help.xml
Module Name: retirement
online version:
schema: 2.0.0
---

# Get-WAFResourceRetirement

## SYNOPSIS

Retrieves active retirement health advisory events based on the specified subscription ID.

## SYNTAX

```powershell
Get-WAFResourceRetirement [-SubscriptionIds] <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION

The Get-WAFResourceRetirement function takes a subscription ID and retrieves active retirement health advisory events.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> $retirementObjects = Get-WAFResourceRetirement -SubscriptionIds '11111111-1111-1111-1111-111111111111'
```

This example retrieves the recent retirement events for the specified Azure subscription.

## PARAMETERS

### -SubscriptionIds

A subscription ID to retrieves active retirement health advisory events.

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

## OUTPUTS

Returns a list of retirement events, including the name and properties of each event.

## NOTES

Author: Takeshi Katano
Date: 2024-10-02

## RELATED LINKS
