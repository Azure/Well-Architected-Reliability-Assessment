---
external help file: advisor-help.xml
Module Name: advisor
online version:
schema: 2.0.0
---

# Build-WAFAdvisorObject

## SYNOPSIS
Builds a list of advisory objects from Azure Advisor query results.

## SYNTAX

```
Build-WAFAdvisorObject [[-AdvQueryResult] <Object>] [<CommonParameters>]
```

## DESCRIPTION
The Build-WAFAdvisorObject function processes the results of an Azure Advisor query and constructs a list of advisory objects.
Each advisory object contains details such as recommendation ID, type, name, resource ID, subscription ID, resource group, location, category, impact, and description.

## EXAMPLES

### EXAMPLE 1
```
$advQueryResult = Get-WAFAdvisorRecommendations -Subid "12345"
```

## PARAMETERS

### -AdvQueryResult
An array of query results from Azure Advisor.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: Claudio Merola
Date: 2024-08-07

## RELATED LINKS
