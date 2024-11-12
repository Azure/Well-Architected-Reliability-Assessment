---
external help file: advisor-help.xml
Module Name: advisor
online version:
schema: 2.0.0
---

# Get-WAFAllAzGraphResource

## SYNOPSIS
Retrieves all Azure resources using Azure Resource Graph.

## SYNTAX

```
Get-WAFAllAzGraphResource [[-subscriptionIds] <String[]>] [[-query] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFAllAzGraphResource function queries Azure Resource Graph to retrieve all resources based on the provided query and subscription IDs.

## EXAMPLES

### EXAMPLE 1
```
$resources = Get-WAFAllAzGraphResource -subscriptionIds @('sub1', 'sub2')
```

## PARAMETERS

### -subscriptionIds
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

### -query
The query to run against Azure Resource Graph.
Defaults to a query that retrieves basic resource information.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Resources | project id, resourceGroup, subscriptionId, name, type, location
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

### Returns an array of resources.
## NOTES
This function handles pagination using the SkipToken.

## RELATED LINKS
