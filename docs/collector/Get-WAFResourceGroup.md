---
external help file: collector-help.xml
Module Name: collector
online version:
schema: 2.0.0
---

# Get-WAFResourceGroup

## SYNOPSIS
Retrieves all resource groups in the specified subscriptions.

## SYNTAX

```
Get-WAFResourceGroup [[-SubscriptionIds] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFResourceGroup function queries Azure Resource Graph to retrieve all resource groups in the specified subscriptions.

## EXAMPLES

### EXAMPLE 1
```
$resourceGroups = Get-WAFResourceGroup -SubscriptionIds @('sub1', 'sub2')
```

## PARAMETERS

### -SubscriptionIds
An array of subscription IDs to scope the query.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns an array of resource groups.
## NOTES
This function uses the Get-WAFAllAzGraphResource function to perform the query.

## RELATED LINKS
