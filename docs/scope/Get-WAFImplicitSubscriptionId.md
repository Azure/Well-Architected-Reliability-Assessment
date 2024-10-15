---
external help file: scope-help.xml
Module Name: scope
online version:
schema: 2.0.0
---

# Get-WAFImplicitSubscriptionId

## SYNOPSIS
Creates a list of unique subscription IDs based on provided subscription, resource group, and resource filters.

## SYNTAX

```
Get-WAFImplicitSubscriptionId [[-SubscriptionFilters] <Array>] [[-ResourceGroupFilters] <Array>]
 [[-ResourceFilters] <Array>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFImplicitSubscriptionId function takes arrays of subscription filters, resource group filters, and resource filters.
It creates a list of unique subscription IDs based on these filters by combining them, splitting them into subscription IDs, and removing duplicates.

## EXAMPLES

### EXAMPLE 1
```
$subscriptionFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111')
$resourceGroupFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1')
$resourceFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1')
$implicitSubscriptionIds = Get-WAFImplicitSubscriptionId -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters
```

## PARAMETERS

### -SubscriptionFilters
An array of strings representing the subscription filters.
Each string should be a subscription ID or a part of a subscription ID.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceGroupFilters
An array of strings representing the resource group filters.
Each string should be a resource group ID or a part of a resource group ID.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceFilters
An array of strings representing the resource filters.
Each string should be a resource ID or a part of a resource ID.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Returns an array of unique subscription IDs.
## NOTES
This function assumes that the input filters are valid and properly formatted.

## RELATED LINKS
