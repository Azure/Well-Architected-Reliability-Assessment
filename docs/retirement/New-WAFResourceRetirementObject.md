---
external help file: retirement-help.xml
Module Name: retirement
online version:
schema: 2.0.0
---

# New-WAFResourceRetirementObject

## SYNOPSIS

Creates a retirement object.

## SYNTAX

```powershell
New-WAFResourceRetirementObject [-SubscriptionId] <String> [-TrackingId] <String> [-Status] <String>
 [-LastUpdateTime] <DateTime> [-StartTime] <DateTime> [-EndTime] <DateTime> [-Level] <String> [-Title] <String>
 [-Summary] <String> [-Header] <String> [-ImpactedService] <String[]> [-Description] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

The New-WAFResourceRetirementObject function creates a retirement object based on the specified parameters.

## EXAMPLES

### EXAMPLE 1

```powershell
PS> $retirementObject = New-WAFResourceRetirementObject -SubscriptionId $subscriptionId -TrackingId 'XXXX-XXX' -Status 'Active' -LastUpdateTime $lastUpdateTime -StartTime $startTime -EndTime $endTime -Level 'Warning' -Title $title -Summary $summary -Header $header -ImpactedService $impactedServices -Description $description
```

## PARAMETERS

### -SubscriptionId

The subscription ID of the retirement event.

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

### -TrackingId

The tracking ID of the retirement event. It's usually as the XXXX-XXX format.

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

### -Status

The status of the retirement event. It's usually Active or Resolved.

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

### -LastUpdateTime

The last update time of the retirement event.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime

The impact start time of the retirement event.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime

The impact mitigation time of the retirement event.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Level

The level of the retirement event such as Warning, etc.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title

The title of the retirement event.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Summary

The summary of the retirement event.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Header

The header of the retirement event.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImpactedService

The impacted services of the retirement event.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

The description of the retirement event.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

Author: Takeshi Katano
Date: 2024-10-02

## RELATED LINKS
