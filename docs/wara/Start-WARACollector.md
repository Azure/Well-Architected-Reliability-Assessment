
# Start-WARACollector

## SYNOPSIS
Starts the WARA Collector process.

## SYNTAX

### Default (Default)
```
Start-WARACollector [-SAP] [-AVD] [-AVS] [-HPC] [-SubscriptionIds <String[]>] [-ResourceGroups <String[]>]
 -TenantID <Guid> [-Tags <String[]>] [-AzureEnvironment <String>] [-RecommendationDataUri <String>]
 [-RecommendationResourceTypesUri <String>] [-UseImplicitRunbookSelectors] [-RunbookFile <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ConfigFileSet
```
Start-WARACollector [-SAP] [-AVD] [-AVS] [-HPC] -ConfigFile <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Specialized
```
Start-WARACollector [-SAP] [-AVD] [-AVS] [-HPC] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Start-WARACollector function initiates the WARA Collector process, which collects and processes data based on the specified parameters.
It supports multiple parameter sets, including Default, Specialized, and ConfigFileSet.

## EXAMPLES

### EXAMPLE 1
```
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000"
```

### EXAMPLE 2
```
Start-WARACollector -ConfigFile "C:\path\to\config.txt"
```

### EXAMPLE 3
```
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000" -ResourceGroups "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-001" -Tags "Env||Environment!~Dev||QA" -AVD -SAP -HPC
```

### EXAMPLE 4
```
Start-WARACollector -ConfigFile "C:\path\to\config.txt" -SAP -AVD
```

## PARAMETERS

### -SAP
Switch to enable SAP workload processing.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AVD
Switch to enable AVD workload processing.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AVS
Switch to enable AVS workload processing.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HPC
Switch to enable HPC workload processing.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubscriptionIds
Array of subscription IDs to include in the process.
Validated using Test-WAFSubscriptionId.

```yaml
Type: String[]
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceGroups
Array of resource groups to include in the process.
Validated using Test-WAFResourceGroupId.

```yaml
Type: String[]
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantID
The tenant ID to use for the process.
This parameter is mandatory and validated using Test-WAFIsGuid.

```yaml
Type: Guid
Parameter Sets: Default
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tags
Array of tags to include in the process.
Validated using Test-WAFTagPattern.

```yaml
Type: String[]
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureEnvironment
Specifies the Azure environment to use.
Default is 'AzureCloud'.
Valid values are 'AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', and 'AzureChinaCloud'.

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: AzureCloud
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigFile
Path to the configuration file.
This parameter is mandatory for the ConfigFileSet parameter set and validated using Test-Path.
See config file example [here](configfile.example).

```yaml
Type: String
Parameter Sets: ConfigFileSet
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecommendationDataUri
URI for the recommendation data.
Default is 'https://azure.github.io/WARA-Build/objects/recommendations.json'.

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: https://azure.github.io/WARA-Build/objects/recommendations.json
Accept pipeline input: False
Accept wildcard characters: False
```

### -RecommendationResourceTypesUri
URI for the recommendation resource types.
Default is 'https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/WARAinScopeResTypes.csv'.

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: https://raw.githubusercontent.com/Azure/Azure-Proactive-Resiliency-Library-v2/refs/heads/main/tools/WARAinScopeResTypes.csv
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseImplicitRunbookSelectors
Switch to enable the use of implicit runbook selectors.

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RunbookFile
Path to the runbook file.
Validated using Test-Path.

```yaml
Type: String
Parameter Sets: Default
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

## NOTES
Author: Kyle Poineal
Date: 12/11/2024

## RELATED LINKS
