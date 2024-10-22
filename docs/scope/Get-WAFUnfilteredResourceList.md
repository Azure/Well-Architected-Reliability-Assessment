---
external help file: scope-help.xml
Module Name: scope
online version:
schema: 2.0.0
---

# Get-WAFUnfilteredResourceList

## SYNOPSIS
Retrieves unfiltered resources from Azure based on provided subscription, resource group, and resource filters.

## SYNTAX

```
Get-WAFUnfilteredResourceList [[-ImplicitSubscriptionId] <Array>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFUnfilteredResourceList function takes an array of implicit subscription IDs and retrieves unfiltered resources from Azure using these subscription IDs.

## EXAMPLES

### EXAMPLE 1
```
$implicitSubscriptionIds = @('/subscriptions/11111111-1111-1111-1111-111111111111')
$unfilteredResources = Get-WAFUnfilteredResourceList -ImplicitSubscriptionId $implicitSubscriptionIds
```

## PARAMETERS

### -ImplicitSubscriptionId
An array of strings representing the implicit subscription IDs.
Each string should be a subscription ID.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns an array of unfiltered resources from Azure.
## NOTES
This function assumes that the Get-WAFAllAzGraphResource function is defined and available in the current context.
It also assumes that Azure authentication has been set up.

## RELATED LINKS
