---
external help file: utils-help.xml
Module Name: utils
online version:
schema: 2.0.0
---

# Import-WAFAPRLJSON

## SYNOPSIS
Imports JSON data from a file.

## SYNTAX

```
Import-WAFAPRLJSON [-file] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Import-WAFAPRLJSON function reads the content of a JSON file, converts it to a PowerShell object, and returns it.

## EXAMPLES

### EXAMPLE 1
```
$jsonData = Import-WAFAPRLJSON -file "data.json"
```

## PARAMETERS

### -file
The path to the JSON file.

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

### Returns a PowerShell object containing the JSON data.
## NOTES

## RELATED LINKS
