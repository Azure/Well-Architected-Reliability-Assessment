---
external help file: collector-help.xml
Module Name: collector
online version:
schema: 2.0.0
---

# Get-WAFTaggedResource

## SYNOPSIS
Retrieves all resources with matching tags.

## SYNTAX

```
Get-WAFTaggedResource [[-tagArray] <Array>] [[-subscriptionIds] <String[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFTaggedResources function queries Azure Resource Graph to retrieve all resources that have matching tags.

## EXAMPLES

### EXAMPLE 1
```
$taggedResources = Get-WAFTaggedResources -tagArray @('env==prod', 'app==myapp') -SubscriptionIds @('sub1', 'sub2')
```

## PARAMETERS

### -tagArray
An array of tags to filter resources by.
Each tag should be in the format 'key==value'.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -subscriptionIds
An array of subscription IDs to scope the query.

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

### Returns an array of resources with matching tags.
## NOTES
This function uses the Invoke-WAFQuery function to perform the query.

## RELATED LINKS
