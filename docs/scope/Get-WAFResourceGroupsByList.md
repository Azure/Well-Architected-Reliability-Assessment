---
external help file: scope-help.xml
Module Name: scope
online version:
schema: 2.0.0
---

# Get-WAFResourceGroupsByList

## SYNOPSIS
Filters a list of objects based on resource group identifiers.

## SYNTAX

```
Get-WAFResourceGroupsByList [-ObjectList] <Array> [-FilterList] <Array> [-KeyColumn] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-WAFResourceGroupsByList function takes a list of objects and filters them based on the specified resource group identifiers.
It compares the first five segments of the KeyColumn property of each object with the provided filter list.

## EXAMPLES

### EXAMPLE 1
```
$objectList = @(
    @{ Id = "/subscriptions/12345/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM" },
    @{ Id = "/subscriptions/12345/resourceGroups/anotherResourceGroup/providers/Microsoft.Compute/virtualMachines/anotherVM" }
)
$filterList = @("/subscriptions/12345/resourceGroups/myResourceGroup")
```

$filteredObjects = Get-WAFResourceGroupsByList -ObjectList $objectList -FilterList $filterList -KeyColumn "Id"

## PARAMETERS

### -ObjectList
An array of objects to be filtered.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterList
An array of resource group identifiers to filter the objects.

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyColumn
The name of the property in the objects that contains the resource group identifier.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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

## NOTES
Author: Kyle Poineal
Date: 2024-08-07

## RELATED LINKS
