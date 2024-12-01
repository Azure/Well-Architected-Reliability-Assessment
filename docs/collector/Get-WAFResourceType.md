---
external help file: collector-help.xml
Module Name: collector
online version:
schema: 2.0.0
---

# Get-WAFResourceType

## SYNOPSIS
Retrieves all resource types in the specified subscriptions.

## SYNTAX

```
Get-WAFResourceType [-SubscriptionIds] <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFResourceType function queries Azure Resource Graph to retrieve all resource types in the specified subscriptions.

## EXAMPLES

### EXAMPLE 1
```
$resourceTypes = Get-WAFResourceType -SubscriptionIds @('sub1', 'sub2')
```

## PARAMETERS

### -SubscriptionIds
An array of subscription IDs to scope the query.

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

### Returns an array of resource types.
## NOTES
This function uses the Get-WAFAllAzGraphResource function to perform the query.

## RELATED LINKS
