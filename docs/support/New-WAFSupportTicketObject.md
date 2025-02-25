---
external help file: support-help.xml
Module Name: support
online version:
schema: 2.0.0
---

# New-WAFSupportTicketObject

## SYNOPSIS

Creates a service ticket object.

## SYNTAX

```powershell
New-WAFSupportTicketObject [-SupportTicketId] <String> [-Severity] <String> [-Status] <String>
 [-SupportPlanType] <String> [-CreatedDate] <DateTime> [-ModifiedDate] <DateTime> [-Title] <String>
 [-TechnicalTicketDetailsResourceId] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION

The New-WAFSupportTicketObject function creates a service ticket based on the specified parameters.

## EXAMPLES

### Example 1

```powershell
PS> $serviceTiketObject = New-WAFSupportTicketObject -SupportTicketId '0123456789012345' -Severity 'Moderate' -Status 'Open' -SupportPlanType 'Unified Enterprise' -CreatedDate $createdDate -ModifiedDate $modifiedDate -Title $title -TechnicalTicketDetailsResourceId $resourceId
```

## PARAMETERS

### -SupportTicketId

The ID of the support ticket. It's usually sixteen digits of number.

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

### -Severity

The severity of the support ticket such as Minimal, Moderate, etc.

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

The status of the support ticket. It's usually Open or Closed.

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

### -SupportPlanType

The support plan type of the support ticket such as Unified Enterprise, etc.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedDate

The created date of the support ticket.

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

### -ModifiedDate

The modified date of the support ticket.

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

### -Title

The title of the support ticket.

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

### -TechnicalTicketDetailsResourceId

The resource ID of the related Azure resource to the support ticket if it's available.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

Returns a SupportTicketObject as a PSCustomObject.

## NOTES

Author: Takeshi Katano
Date: 2024-11-08

## RELATED LINKS
