---
external help file: retirement-help.xml
Module Name: retirement
online version:
schema: 2.0.0
---

# Invoke-AzureRestApi

## SYNOPSIS
Invokes an Azure REST API then returns the response.

## SYNTAX

### WithoutResourceGroup
```
Invoke-AzureRestApi -Method <String> -SubscriptionId <String> -ResourceProviderName <String>
 -ResourceType <String> -ApiVersion <String> [-QueryString <String>] [-RequestBody <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### WithResourceGroup
```
Invoke-AzureRestApi -Method <String> -SubscriptionId <String> -ResourceGroupName <String>
 -ResourceProviderName <String> -ResourceType <String> -Name <String> -ApiVersion <String>
 [-QueryString <String>] [-RequestBody <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Invoke-AzureRestApi function invokes an Azure REST API with the specified parameters then return the response.

## EXAMPLES

### EXAMPLE 1
```
$response = Invoke-AzureRestApi -Method 'GET' -SubscriptionId '11111111-1111-1111-1111-111111111111' -ResourceProviderName 'Microsoft.ResourceHealth' -ResourceType 'events' -ApiVersion '2024-02-01' -QueryString 'queryStartTime=2024-10-02T00:00:00'
```

## PARAMETERS

### -Method
The HTTP method to invoke the Azure REST API.

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

### -SubscriptionId
The subscription ID that constitutes the URI for invoke the Azure REST API.

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
The resource group name that constitutes the URI for invoke the Azure REST API.

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
The resource provider name that constitutes the URI for invoke the Azure REST API.

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
The resource type that constitutes the URI for invoke the Azure REST API.

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
The resource name that constitutes the URI for invoke the Azure REST API.

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
The Azure REST API version that constitutes the URI for invoke the Azure REST API.

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
The query string that constitutes the URI for invoke the Azure REST API.

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

### -RequestBody
The request body for invoke the Azure REST API.

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

### Microsoft.Azure.Commands.Profile.Models.PSHttpResponse
## NOTES
Author: Takeshi Katano
Date: 2024-10-02

This function should be placed in a common module such as a utility module because this is common feature across modules.

## RELATED LINKS
