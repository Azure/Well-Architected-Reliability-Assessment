---
external help file: collector-help.xml
Module Name: collector
online version:
schema: 2.0.0
---

# Import-WAFConfigFileData

## SYNOPSIS
Imports configuration data from a file.

## SYNTAX

```
Import-WAFConfigFileData [-ConfigFile] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Import-WAFConfigFileData function reads the content of a configuration file, extracts sections, and returns the data as a PSCustomObject.

## EXAMPLES

### EXAMPLE 1
```
$configData = Import-WAFConfigFileData -file "config.txt"
```

## PARAMETERS

### -ConfigFile
{{ Fill ConfigFile Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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

### Returns a PSCustomObject containing the configuration data.
## NOTES

## RELATED LINKS
