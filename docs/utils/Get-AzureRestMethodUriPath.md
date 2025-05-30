---
external help file: utils-help.xml
Module Name: utils
online version:
schema: 2.0.0
---

# Get-AzureRestMethodUriPath

## SYNOPSIS

Retrieves the path of the Azure REST API URI.

## SYNTAX

### WithoutResourceGroup

```powershell
Get-AzureRestMethodUriPath -SubscriptionId <String> -ResourceProviderName <String> -ResourceType <String>
 -ApiVersion <String> [-QueryString <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### WithResourceGroup

```powershell
Get-AzureRestMethodUriPath -SubscriptionId <String> -ResourceGroupName <String> -ResourceProviderName <String>
 -ResourceType <String> -Name <String> -ApiVersion <String> [-QueryString <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

The Get-AzureRestMethodUriPath function retrieves the formatted path of the Azure REST API URI based on the specified URI parts as parameters.
The path represents the Azure REST API URI without the protocol (e.g. https), host (e.g. management.azure.com).

For example, /subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/stsample1234?api-version=2024-01-01

## EXAMPLES

### EXAMPLE 1

```powershell
$path = Get-AzureRestMethodUriPath -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceGroupName 'rg1' -ResourceProviderName 'Microsoft.Storage' -ResourceType 'storageAccounts' -Name 'stsample1234' -ApiVersion '2024-01-01' -QueryString 'param1=value1'
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

The resource provider name that constitutes the path of Azure REST API URI. It's usually as the XXXX.XXXX format.

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

The Azure REST API version that constitutes the path of Azure REST API URI. It's usually as the yyyy-mm-dd format.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

Returns a URI path to call Azure REST API.

## NOTES

Author: Takeshi Katano
Date: 2024-10-23

## RELATED LINKS
