---
external help file: retirement-help.xml
Module Name: retirement
online version:
schema: 2.0.0
---

# Get-AzureRestMethodUriPath

## SYNOPSIS
Retrieves the path of the Azure REST API URI.

## SYNTAX

### WithoutResourceGroup
```
Get-AzureRestMethodUriPath -SubscriptionId <String> -ResourceProviderName <String> -ResourceType <String>
 -ApiVersion <String> [-QueryString <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### WithResourceGroup
```
Get-AzureRestMethodUriPath -SubscriptionId <String> -ResourceGroupName <String> -ResourceProviderName <String>
 -ResourceType <String> -Name <String> -ApiVersion <String> [-QueryString <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-AzureRestMethodUriPath function retrieves the formatted path of the Azure REST API URI based on the specified URI parts as parameters.
The path represents the Azure REST API URI without the protocol (e.g.
https), host (e.g.
management.azure.com).
For example,
/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/stsample1234?api-version=2024-01-01

## EXAMPLES

### EXAMPLE 1
```
$path = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceGroupName 'rg1' -ResourceProviderName 'Microsoft.Storage' -ResourceType 'storageAccounts' -Name 'stsample1234' -ApiVersion '2024-01-01'
```

## PARAMETERS

### -SubscriptionId
The subscription ID that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceGroupName
The resource group name that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: WithResourceGroup
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceProviderName
The resource provider name that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceType
The resource type that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The resource name that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: WithResourceGroup
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiVersion
The Azure REST API version that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -QueryString
The query string that constitutes the path of Azure REST API URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

### System.String
## NOTES
Author: Takeshi Katano
Date: 2024-10-02

This function should be placed in a common module such as a utility module because this is common feature across modules.

## RELATED LINKS
