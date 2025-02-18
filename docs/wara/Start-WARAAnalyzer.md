---
external help file: wara-help.xml
Module Name: wara
online version: https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
schema: 2.0.0
---

# Start-WARAAnalyzer

## SYNOPSIS
Well-Architected Reliability Assessment Script

## SYNTAX

```
Start-WARAAnalyzer [[-RecommendationsUrl] <String>] [-JSONFile] <String> [[-ExpertAnalysisFile] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The function `Start-WARAAnalyzer` will process the JSON file created by the \`Start-WARACollector\` function and will create the core WARA Action Plan Excel file.

## EXAMPLES

### EXAMPLE 1
```Powershell
Start-WARAAnalyzer -JSONFile 'C:\Temp\WARA_File_2024-04-01_10_01.json'
```

### EXAMPLE 2
```Powershell
Start-WARAAnalyzer -JSONFile 'C:\Temp\WARA_File_2024-04-01_10_01.json' -Debug
```

## PARAMETERS

### -RecommendationsUrl
This is the URL to the JSON file that contains the recommendations. The default value is the URL to the recommendations object stored at https://azure.github.io/WARA-Build/objects/recommendations.json

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Https://azure.github.io/WARA-Build/objects/recommendations.json
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpertAnalysisFile
This is the path to the ExpertAnalysisTemplate file. It is packaged with the module and generally you should not need to adjust this.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

