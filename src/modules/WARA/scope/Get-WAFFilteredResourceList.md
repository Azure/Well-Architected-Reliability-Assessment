---
external help file: scope-help.xml
Module Name: scope
online version:
schema: 2.0.0
---

# Get-WAFFilteredResourceList

## SYNOPSIS
Retrieves a filtered list of Azure resources based on subscription, resource group, and resource filters.

## SYNTAX

```
Get-WAFFilteredResourceList [[-SubscriptionFilters] <String[]>] [[-ResourceGroupFilters] <String[]>]
 [[-ResourceFilters] <String[]>] [[-UnfilteredResources] <String[]>]
```

## DESCRIPTION
The Get-WAFFilteredResourceList function filters Azure resources by combining subscription, resource group, and resource filters.
It generates a list of implicit subscription IDs from the provided filters, retrieves unfiltered resources, and then applies the filters to return the matching resources.

## EXAMPLES

### EXAMPLE 1
```
$subscriptionFilters = @("/subscriptions/12345")
$resourceGroupFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup")
$resourceFilters = @("/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM")
```

$filteredResources = Get-WAFFilteredResourceList -SubscriptionFilters $subscriptionFilters -ResourceGroupFilters $resourceGroupFilters -ResourceFilters $resourceFilters

## PARAMETERS

### -SubscriptionFilters
An array of subscription identifiers to filter the resources.

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
An array of resource group identifiers to filter the resources.

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
An array of resource identifiers to filter the resources.

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

### -UnfilteredResources
{{ Fill UnfilteredResources Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Author: Your Name
Date: 2024-08-07

## RELATED LINKS
