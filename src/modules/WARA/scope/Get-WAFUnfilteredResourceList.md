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
Get-WAFUnfilteredResourceList [[-SubscriptionFilters] <String[]>] [[-ResourceGroupFilters] <String[]>]
 [[-ResourceFilters] <String[]>]
```

## DESCRIPTION
The Get-WAFUnfilteredResource function takes arrays of subscription filters, resource group filters, and resource filters.
It creates a list of unique subscription IDs based on these filters and retrieves unfiltered resources from Azure using these subscription IDs.

## EXAMPLES

### EXAMPLE 1
```
$subscriptionFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111')
$resourceGroupFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1')
$resourceFilters = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/test1/providers/Microsoft.Compute/virtualMachines/TestVM1')
$unfilteredResources = Get-WAFUnfilteredResource -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters
```

## PARAMETERS

### -SubscriptionFilters
An array of strings representing the subscription filters.
Each string should be a subscription ID or a part of a subscription ID.

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

### -ResourceGroupFilters
An array of strings representing the resource group filters.
Each string should be a resource group ID or a part of a resource group ID.

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

### -ResourceFilters
An array of strings representing the resource filters.
Each string should be a resource ID or a part of a resource ID.

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

## INPUTS

## OUTPUTS

### Returns an array of unfiltered resources from Azure.
## NOTES
This function assumes that the Get-WAFAllAzGraphResource function is defined and available in the current context.
It also assumes that Azure authentication has been set up.

## RELATED LINKS
