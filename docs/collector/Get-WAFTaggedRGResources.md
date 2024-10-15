---
external help file: collector-help.xml
Module Name: collector
online version:
schema: 2.0.0
---

# Get-WAFTaggedRGResources

## SYNOPSIS
Retrieves all resources in resource groups with matching tags.

## SYNTAX

```
Get-WAFTaggedRGResources [[-tagKeys] <String[]>] [[-tagValues] <String[]>] [[-SubscriptionIds] <String[]>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFTaggedRGResources function queries Azure Resource Graph to retrieve all resources in resource groups that have matching tags.

## EXAMPLES

### EXAMPLE 1
```
$taggedRGResources = Get-WAFTaggedRGResources -tagKeys @('env') -tagValues @('prod') -SubscriptionIds @('sub1', 'sub2')
```

## PARAMETERS

### -tagKeys
An array of tag keys to filter resource groups by.

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

### -tagValues
An array of tag values to filter resource groups by.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubscriptionIds
An array of subscription IDs to scope the query.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns an array of resources in resource groups with matching tags.
## NOTES
This function uses the Get-WAFAllAzGraphResource function to perform the query.

## RELATED LINKS
