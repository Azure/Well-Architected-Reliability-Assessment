---
external help file: support-help.xml
Module Name: support
online version:
schema: 2.0.0
---

# Connect-WAFAzure

## SYNOPSIS
Connects to an Azure tenant.

## SYNTAX

```
Connect-WAFAzure [-TenantID] <Guid> [[-AzureEnvironment] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Connect-WAFAzure function connects to an Azure tenant using the provided Tenant ID and Subscription IDs.

## EXAMPLES

### EXAMPLE 1
```
Connect-WAFAzure -TenantID "your-tenant-id" -SubscriptionIds @("sub1", "sub2") -AzureEnvironment "AzureCloud"
```

## PARAMETERS

### -TenantID
The Tenant ID to connect to.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureEnvironment
The Azure environment to connect to.
Defaults to 'AzureCloud'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: AzureCloud
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

### None.
## NOTES

## RELATED LINKS
