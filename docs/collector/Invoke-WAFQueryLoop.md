---
external help file: collector-help.xml
Module Name: collector
online version:
schema: 2.0.0
---

# Invoke-WAFQueryLoop

## SYNOPSIS
Invokes a loop to run queries for each recommendation object.

## SYNTAX

```
Invoke-WAFQueryLoop [[-RecommendationObject] <Object>] [[-subscriptionIds] <String[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Invoke-WAFQueryLoop function runs queries for each recommendation object and retrieves the resources.

## EXAMPLES

### EXAMPLE 1
```
$resources = Invoke-WAFQueryLoop -RecommendationObject $recommendations -subscriptionIds @('sub1', 'sub2')
```

## PARAMETERS

### -RecommendationObject
An array of recommendation objects to query.

```yaml
Type: Object
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

### Returns an array of resources for each recommendation object.
## NOTES
This function uses the Get-WAFAllAzGraphResource function to perform the queries.

## RELATED LINKS
