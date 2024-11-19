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

```
Get-WAFResourceRetirement [-SubscriptionIds] <String[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFResourceRetirement function takes a subscription ID and retrieves active retirement health advisory events.

## EXAMPLES

### EXAMPLE 1
```
$retirementObjects = Get-WAFResourceRetirement -SubscriptionId '11111111-1111-1111-1111-111111111111'
```

## PARAMETERS

### -SubscriptionIds
{{ Fill SubscriptionIds Description }}

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

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject[]
## NOTES
Author: Takeshi Katano
Date: 2024-10-02

## RELATED LINKS
