
# Start-WARAReport

## SYNOPSIS
Well-Architected Reliability Assessment Report Generator Function

## SYNTAX

```
Start-WARAReport [-Help] [-Debugging] [[-CustomerName] <String>] [[-WorkloadName] <String>]
 [-ExcelFile] <String> [-Heavy] [[-PPTTemplateFile] <String>] [[-WordTemplateFile] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The function \`Start-WARAReport\` processes the Excel file created by the \`Start-WARAAnalyzer\` command and generates the final PowerPoint and Word reports for the Well-Architected Reliability Assessment.

## EXAMPLES

### EXAMPLE 1
```
Start-WARAReport -ExcelFile 'C:\WARA_Script\WARA Action Plan 2024-03-07_16_06.xlsx' -CustomerName 'ABC Customer' -WorkloadName 'SAP On Azure' -Heavy -PPTTemplateFile 'C:\Templates\Template.pptx' -WordTemplateFile 'C:\Templates\Template.docx'
```

## PARAMETERS

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

### -CustomerName
Name of the customer for whom the report is being generated.

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

### -WorkloadName
Name of the workload being assessed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcelFile
Path to the Excel file created by the "2_wara_data_analyzer" script.

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

### -Heavy
Switch to enable heavy processing mode.
When enabled, this mode introduces additional delays using Start-Sleep at various points in the script to handle heavy environments more gracefully.
This can help in scenarios where the system resources are limited or the operations being performed are resource-intensive, ensuring the script doesn't overwhelm the system.

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

### -PPTTemplateFile
Path to the PowerPoint template file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WordTemplateFile
Path to the Word template file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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

