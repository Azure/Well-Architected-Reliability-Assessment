---
external help file: analyzer-help.xml
Module Name: analyzer
online version: https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
schema: 2.0.0
---

# Start-WARAAnalyzer

## SYNOPSIS
Well-Architected Reliability Assessment Script

## SYNTAX

```
Start-WARAAnalyzer [-Debugging] [-Help] [[-CustomRecommendationsYAMLPath] <String>] [[-RepoUrl] <String>]
 [-JSONFile] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The function \`Start-WARAAnalyzer\` will process the JSON file created by the \`Start-WARACollector\` function and will create the core WARA Action Plan Excel file.

## EXAMPLES

### EXAMPLE 1
```
Start-WARAAnalyzer -JSONFile 'C:\Temp\WARA_File_2024-04-01_10_01.json' -Debugging
```

## PARAMETERS

### -Debugging
Switch to enable debugging mode.

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

### -Help
Switch to display help information.

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

### -CustomRecommendationsYAMLPath
{{ Fill CustomRecommendationsYAMLPath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RepoUrl
Specifies the git repository URL that contains APRL contents if you want to use custom APRL repository.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
Accept pipeline input: False
Accept wildcard characters: False
```

### -JSONFile
Path to the JSON file created by the "1_wara_collector" script.

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

## RELATED LINKS

[https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2](https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2)

