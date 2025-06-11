#Requires -Version 7

<#
.SYNOPSIS
Well-Architected Reliability Assessment Report Generator Script

.DESCRIPTION
The script "3_wara_reports_generator" processes the Excel file created by the "2_wara_data_analyzer" script and generates the final PowerPoint and Word reports for the Well-Architected Reliability Assessment.

.PARAMETER Help
Switch to display help information.

.PARAMETER CustomerName
Name of the customer for whom the report is being generated.

.PARAMETER WorkloadName
Name of the workload being assessed.

.PARAMETER ExcelFile
Path to the Excel file created by the "2_wara_data_analyzer" script.

.PARAMETER Heavy
Switch to enable heavy processing mode. When enabled, this mode introduces additional delays using Start-Sleep at various points in the script to handle heavy environments more gracefully. This can help in scenarios where the system resources are limited or the operations being performed are resource-intensive, ensuring the script doesn't overwhelm the system.

.PARAMETER PPTTemplateFile
Path to the PowerPoint template file.

.EXAMPLE
.\3_wara_reports_generator.ps1 -ExcelFile 'C:\WARA_Script\WARA Action Plan 2024-03-07_16_06.xlsx' -CustomerName 'ABC Customer' -WorkloadName 'SAP On Azure' -Heavy -PPTTemplateFile 'C:\Templates\Template.pptx' -WordTemplateFile 'C:\Templates\Template.docx'

.LINK
https://github.com/Azure/Azure-Proactive-Resiliency-Library-v2
#>

Param(
    [switch] $Help,

    #[switch] $csvExport,

    [switch] $includeLow,

    [Parameter(Mandatory = $false)]
    [string] $CustomerName = '[Customer Name]',

    [Parameter(Mandatory = $false)]
    [string] $WorkloadName = '[Workload Name]',

    [Parameter(Mandatory = $true)]
    [Alias('ExcelFile')]
    [string] $ExpertAnalysisFile,

    [Parameter(Mandatory = $false)]
    [string] $AssessmentFindingsFile = (Join-Path -Path $PSScriptRoot -ChildPath 'Assessment-Findings-Report-v1.xlsx'),

    [Parameter(Mandatory = $false)]
    [string] $PPTTemplateFile = (Join-Path -Path $PSScriptRoot -ChildPath 'Mandatory - Executive Summary presentation - Template.pptx')
)

$ErrorActionPreference = 'Stop'

trap {
    $ex = $_.Exception
    $horizontalLineLength = 40

    $builder = New-Object -TypeName 'System.Text.StringBuilder'
    [void] $builder.AppendLine('')
    [void] $builder.AppendLine($ex.Message)
    [void] $builder.AppendLine('')

    [void] $builder.AppendLine('*' * $horizontalLineLength)
    [void] $builder.AppendLine('Exception                : ' + $ex.GetType().FullName)
    [void] $builder.AppendLine('FullyQualifiedErrorId    : ' + $_.FullyQualifiedErrorId)
    [void] $builder.AppendLine('ErrorDetailsMessage      : ' + $_.ErrorDetails.Message)
    [void] $builder.AppendLine('CategoryInfo             : ' + $_.CategoryInfo.ToString())
    [void] $builder.AppendLine('StackTrace in PowerShell :')
    [void] $builder.AppendLine($_.ScriptStackTrace)

    [void] $builder.AppendLine('')
    [void] $builder.AppendLine('---- Exception Details ----')
    [void] $builder.AppendLine('Exception  : ' + $ex.GetType().FullName)
    [void] $builder.AppendLine('Message    : ' + $ex.Message)
    [void] $builder.AppendLine('Source     : ' + $ex.Source)
    [void] $builder.AppendLine('HResult    : ' + $ex.HResult)
    [void] $builder.AppendLine('StackTrace :')
    [void] $builder.AppendLine($ex.StackTrace)

    $depth = 1
    while ($ex.InnerException) {
        $ex = $ex.InnerException
        [void] $builder.AppendLine('')
        [void] $builder.AppendLine('---- Inner Exception Details {0} ----' -f $depth)
        [void] $builder.AppendLine('Exception  : ' + $ex.GetType().FullName)
        [void] $builder.AppendLine('Message    : ' + $ex.Message)
        [void] $builder.AppendLine('Source     : ' + $ex.Source)
        [void] $builder.AppendLine('HResult    : ' + $ex.HResult)
        [void] $builder.AppendLine('StackTrace :')
        [void] $builder.AppendLine($ex.StackTrace)
        $depth++
    }

    [void] $builder.AppendLine('*' * $horizontalLineLength)
    $builder.ToString() | Write-Host -ForegroundColor Yellow

    break
}

# Checking the operating system running this script.
if (-not $IsWindows) {
    throw 'This script only supports Windows operating systems currently. Please try to run with Windows operating systems.'
}

# Check if Clipboard History is enabled
$clipboardHistory = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name 'EnableClipboardHistory' -ErrorAction SilentlyContinue

if ($clipboardHistory.EnableClipboardHistory -eq 1) {
    throw 'Clipboard History is enabled. Please disable Clipboard History before running this script. See more details at https://aka.ms/waratools/faq'
}
else {
    Write-Debug 'Clipboard History is disabled.'
}

# Verify the PPTTemplateFile parameter
$pptTemplateFilePath = (Resolve-Path -LiteralPath $PPTTemplateFile).Path
if (-not (Test-Path -PathType Leaf -LiteralPath $pptTemplateFilePath)) {
    throw 'The specified PowerPoint template file "{0}" is not a file. Please provide the path to the PowerPoint template file.' -f $pptTemplateFilePath
}
Write-Host ('PowerPoint Template File: {0}' -f $pptTemplateFilePath)

# Verify the AssessmentFindingsFile parameter
$assessmentFindingsFilePath = (Resolve-Path -LiteralPath $AssessmentFindingsFile).Path
if (-not (Test-Path -PathType Leaf -LiteralPath $assessmentFindingsFilePath)) {
    throw 'The specified Assessment Findings file "{0}" is not a file. Please provide the path to the Assessment Findings file.' -f $assessmentFindingsFilePath
}
Write-Host ('Assessment Findings File: {0}' -f $assessmentFindingsFilePath)

$TableStyle = 'Light19'

######################## REGULAR Functions ##########################

function Test-ReviewedRecommendations {
    Param($ExcelFile)

    $ExcelContent = Import-Excel -Path $ExcelFile -WorksheetName '4.ImpactedResourcesAnalysis' -StartRow 12

    if (($ExcelContent | Where-Object { $_.Impact -ne 'Low' -and $_.'REQUIRED ACTIONS / REVIEW STATUS' -ne 'Reviewed' -and ![String]::IsNullOrEmpty($_.'REQUIRED ACTIONS / REVIEW STATUS') }).count -ge 1) {
        Write-Host ""
        Write-Host "There are still some recommendations that need to be reviewed." -ForegroundColor Yellow
        Write-Host "Please review all the recommendations in the Expert-Analysis file before running the report generator." -ForegroundColor Yellow
        Write-Host ""
        Exit
    }
}

function New-AssessmentFindingsFile {
    Param(
        [string]$AssessmentFindingsFile
    )

    $workingFolderPath = Get-Location
    $workingFolderPath = $workingFolderPath.Path
    $ExcelPkg = Open-ExcelPackage -Path $AssessmentFindingsFile
    $NewAssessmentFindings = ($workingFolderPath + '\Assessment-Findings-Report-v1-' + (Get-Date -Format 'yyyy-MM-dd-HH-mm') + '.xlsx')
    Close-ExcelPackage -ExcelPackage $ExcelPkg -SaveAs $NewAssessmentFindings

    return $NewAssessmentFindings
}

function New-PPTFile {
    Param(
        [string]$PPTTemplateFile  # NEED FIX: PPTTemplateFile parameter does not use in the function
    )

    $workingFolderPath = Get-Location
    $workingFolderPath = $workingFolderPath.Path
    $NewPPTFile = ($workingFolderPath + '\Executive Summary Presentation - ' + $CustomerName + ' - ' + (get-date -Format "yyyy-MM-dd-HH-mm") + '.pptx')

    return $NewPPTFile
}

function Test-Requirement {
    # Install required modules
    Write-Host "Validating " -NoNewline
    Write-Host "ImportExcel" -ForegroundColor Cyan -NoNewline
    Write-Host " Module.."
    $ImportExcel = Get-Module -Name ImportExcel -ListAvailable -ErrorAction silentlycontinue
    if ($null -eq $ImportExcel) {
        Write-Host "Installing ImportExcel Module" -ForegroundColor Yellow
        Install-Module -Name ImportExcel -Force -SkipPublisherCheck
    }
}

function Set-LocalFile {
    # Define script path as the default path to save files
    $workingFolderPath = $PSScriptRoot
    Set-Location -path $workingFolderPath;
    $clonePath = "$workingFolderPath\Azure-Proactive-Resiliency-Library"
    Write-Debug "Checking the version of the script"
    $RepoVersion = Get-Content -Path "$clonePath\tools\Version.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
    if ($Version -ne $RepoVersion.Generator) {
        Write-Host "This version of the script is outdated. " -BackgroundColor DarkRed
        Write-Host "Please use a more recent version of the script." -BackgroundColor DarkRed
    }
    else {
        Write-Host "This version of the script is current version. " -BackgroundColor DarkGreen
    }
}

function Get-ExcelImpactedResources {
    Param($ExcelFile)

    $ExcelContent = Import-Excel -Path $ExcelFile -WorksheetName '4.ImpactedResourcesAnalysis' -StartRow 12
    #$ImpactedResources = $ExcelContent

    return $ExcelContent.where({ ![String]::IsNullOrEmpty($_."Resource Type") })
}

function Get-ExcelWorkloadInventory {
    Param($ExcelFile)

    $ExcelContent = Import-Excel -Path $ExcelFile -WorksheetName '2.WorkloadInventory' -StartRow 12

    return $ExcelContent
}

function Get-ExcelPlatformIssues {
    Param($ExcelFile)

    try {
        $PlatformIssues = Import-Excel -Path $ExcelFile -WorksheetName '5.PlatformIssuesAnalysis' -StartRow 12
    }
    catch {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Platform Issues not found in the Excel File..')
    }

    return $PlatformIssues
}

function Get-ExcelSupportTicket {
    Param($ExcelFile)

    try {
        $SupportTickets = Import-Excel -Path $ExcelFile -WorksheetName "6.SupportRequestsAnalysis" -AsText 'Ticket ID' -StartRow 12
    }
    catch {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Support Tickets not found in the Excel File..')
    }

    return $SupportTickets
}

function Get-ExcelRetirement {
    Param($ExcelFile)

    try {
        $Retirements = Import-Excel -Path $ExcelFile -WorksheetName "4.ImpactedResourcesAnalysis" -StartRow 12
        $Retirements = $Retirements | Where-Object { $_.Source -eq 'Azure Service Health - Service Retirements' }
    }
    catch {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Service Retirements not found in the Excel File..')
    }

    return $Retirements
}

function Build-SummaryActionPlan {
    Param($ImpactedResources, $includeLow)

    if ($includeLow.IsPresent) {
        $Recommendations = $ImpactedResources | Where-Object { $_.impact -in ('High', 'Medium', 'Low') -and $_.ValidationCategory -ne 'Retirements' }
    }
    else {
        $Recommendations = $ImpactedResources | Where-Object { $_.impact -in ('High', 'Medium') -and $_.ValidationCategory -ne 'Retirements' }
    }

    $RecomCount = ($ImpactedResources).count
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Creating CSV file for: ' + $RecomCount + ' recommendations')

    $CXSummaryArray = foreach ($Recommendation in $Recommendations) {
        try {
            $tmp = [PSCustomObject]@{
                'Recommendation Guid'        = $Recommendation.Guid
                'Recommendation Title'       = $Recommendation.'Recommendation Title'
                'Description'                = $Recommendation.'Long Description'
                'Priority'                   = $Recommendation.Impact
                'Customer-facing annotation' = ""
                'Internal-facing notes'      = $Recommendation.notes
                'Potential Benefit'          = $Recommendation.'Potential Benefit'
                'Resource Type'              = $Recommendation.'Resource Type'
                'Resource ID'                = $Recommendation.id
            }
            $tmp
        }
        catch {
            Write-Debug $recommendation
        }
    }
    return $CXSummaryArray
}

######################## PPT Functions ##########################

############# Slide 1
function Remove-PPTSlide1 {
    Param($Presentation, $CustomerName, $WorkloadName)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Removing Slide 1..')

    ($Presentation.Slides | Where-Object { $_.SlideIndex -eq 1 }).Delete()

    $Slide1 = $Presentation.Slides | Where-Object { $_.SlideIndex -eq 1 }

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Slide 1 - Adding Customer name: ' + $CustomerName + '. And Workload name: ' + $WorkloadName)
    ($Slide1.Shapes | Where-Object { $_.Id -eq 5 }).TextFrame.TextRange.Text = ($CustomerName + ' - ' + $WorkloadName)
}

############# SLide 12
function Build-PPTSlide12 {
    Param($Presentation, $AUTOMESSAGE, $WorkloadName, $ResourcesTypes)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 12 - Workload Summary..')

    $SlideWorkloadSummary = $Presentation.Slides | Where-Object { $_.SlideIndex -eq 12 }

    $TargetShape = ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 9 })
    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

    $TargetShape = ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 8 })
    $TargetShape.Delete()

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 12 - Adding Workload name: ' + $WorkloadName)
    ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 3 }).TextFrame.TextRange.Text = ('During the engagement, the Workload ' + $WorkloadName + ' has been reviewed. The solution is hosted in two Azure regions, and runs mainly IaaS resources, with some PaaS resources, which includes but is not limited to:')

    $loop = 1
    foreach ($ResourcesType in $ResourcesTypes) {
        $LogResName = $ResourcesType.Name
        $LogResCount = $ResourcesType.'Count'
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 12 - Adding Resource Type: ' + $LogResName + '. Count: ' + $LogResCount)
        if ($loop -eq 1) {
            $ResourceTemp = ($ResourcesType.Name + ' (' + $ResourcesType.'Count' + ')')
            ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 6 }).Table.Columns(1).Width = 685
            ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 6 }).Table.Rows(1).Cells(1).Shape.TextFrame.TextRange.Text = $ResourceTemp
            ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 6 }).Table.Rows(1).Height = 20
        }
        else {
            $ResourceTemp = ($ResourcesType.Name + ' (' + $ResourcesType.'Count' + ')')
            ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 6 }).Table.Rows.Add() | Out-Null
            ($SlideWorkloadSummary.Shapes | Where-Object { $_.Id -eq 6 }).Table.Rows($loop).Cells(1).Shape.TextFrame.TextRange.Text = $ResourceTemp
        }
        $loop ++
    }
}

############# Slide 16
function Build-PPTSlide16 {
    Param($Presentation, $AUTOMESSAGE, $ImpactedResources)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 16 - Health and Risk Dashboard..')

    $SlideHealthAndRisk = $Presentation.Slides | Where-Object { $_.SlideIndex -eq 16 }

    $TargetShape = ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 41 })
    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

    $ServiceHighImpact = $ImpactedResources | Where-Object { $_.Impact -eq 'High' -and $_.Category -eq 'Azure Service' } | Group-Object -Property 'Recommendation Title' | Sort-Object -Property "Count" -Descending
    #$WAFHighImpact = $ImpactedResources | Where-Object { $_.Impact -eq 'High' -and $_.Category -eq 'Well Architected' } | Group-Object -Property 'Recommendation Title' | Sort-Object -Property "Count" -Descending

    $count = 1
    foreach ($Impact in $ServiceHighImpact) {
        $LogImpactName = $Impact.Name
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 16 - Adding Service High Impact Name: ' + $LogImpactName)
        if ($count -lt 7) {
            ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 9 }).TextFrame.TextRange.Paragraphs($count).text = $Impact.Name
            $count ++
        }
    }

    while (($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 9 }).TextFrame.TextRange.Paragraphs().count -gt 6) {
        ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 9 }).TextFrame.TextRange.Paragraphs(6).Delete()
    }

    <#
    if ($WAFHighImpact.count -ne 0) {
      $count = 1
      foreach ($Impact in $WAFHighImpact) {
        $LogWAFImpactName = $Impact.Name
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 16 - Adding WAF High Impact: ' + $LogWAFImpactName)
        if ($count -lt 5) {
          ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 12 }).TextFrame.TextRange.Paragraphs($count).text = $Impact.Name
          $count ++
        }
      }
    }
    else {
      ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 12 }).TextFrame.TextRange.Text = ' '
    }


    while (($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 12 }).TextFrame.TextRange.Paragraphs().count -gt 5) {
      ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 12 }).TextFrame.TextRange.Paragraphs(6).Delete()
    }
      #>

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 16 - Adding general values...')
    #Total Recomendations
    ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 19 }).TextFrame.TextRange.Text = [string]($ImpactedResources | Select-Object -Property Guid -Unique).count
    #High Impact
    ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 21 }).TextFrame.TextRange.Text = [string]($ImpactedResources | Where-Object { $_.Impact -eq 'High' } | Select-Object -Property Guid -Unique).count
    #Medium Impact
    ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 23 }).TextFrame.TextRange.Text = [string]($ImpactedResources | Where-Object { $_.Impact -eq 'Medium' } | Select-Object -Property Guid -Unique).count
    #Low Impact
    ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 24 }).TextFrame.TextRange.Text = [string]($ImpactedResources | Where-Object { $_.Impact -eq 'Low' } | Select-Object -Property Guid -Unique).count
    #Impacted Resources
    ($SlideHealthAndRisk.Shapes | Where-Object { $_.Id -eq 30 }).TextFrame.TextRange.Text = [string]($ImpactedResources | Select-Object -Property id -Unique).count
}

############# Slide 17
function Build-PPTSlide17 {
    Param($Presentation, $AUTOMESSAGE, $ExcelWorkbooks)

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 17 - Health and Risk Dashboard..')

    $ChartSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq 17 }

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 17 - Adding Automation Message..')
    $TargetShape = ($ChartSlide.Shapes | Where-Object { $_.Id -eq 41 })
    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 17 - Loading Excel Worksheet..')
    $WS = $ExcelWorkbooks.Worksheets | Where-Object { $_.Name -eq '1.Dashboard' }
    Start-Sleep 1

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 17 - Copying Chart P1..')
    $WS.ChartObjects('ChartP1').copy()
    Start-Sleep -Milliseconds 500

    $ChartSlide.Shapes.Paste() | Out-Null
    Start-Sleep 1

    $Shape = $ChartSlide.Shapes | Where-Object { $_.Name -eq 'ChartP1' }

    $Shape.ScaleHeight(0.85, $false)
    Start-Sleep -Milliseconds 500
    $Shape.IncrementLeft(-260)
    Start-Sleep -Milliseconds 500
    $Shape.IncrementTop(77)
    Start-Sleep -Milliseconds 500

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 17 - Copying Chart P0..')
    $WS.ChartObjects('ChartP0').copy()
    Start-Sleep -Milliseconds 500

    $ChartSlide.Shapes.Paste() | Out-Null
    Start-Sleep 1

    $Shape = $ChartSlide.Shapes | Where-Object { $_.Name -eq 'ChartP0' }
    $yAxis = $Shape.Chart.Axes(1)  # 2 corresponds to xlValue for the Y-axis
    $yAxis.TickLabelSpacing = 1
    $Shape.IncrementLeft(240)
    Start-Sleep -Milliseconds 500
}

############# Slide 23
function Build-PPTSlide23 {
    Param($Presentation, $AUTOMESSAGE, $ImpactedResources)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 23 - High Impact Issues..')

    $HighImpact = $ImpactedResources | Where-Object { $_.Impact -eq 'High' } | Group-Object -Property 'Recommendation Title', 'Resource Type' | Sort-Object -Property "Count" -Descending

    $FirstSlide = 23
    $TableID = 6
    $CurrentSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $FirstSlide }

    $TargetShape = ($CurrentSlide.Shapes | Where-Object { $_.Id -eq 41 })
    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 23 - Cleaning Table..')
    $row = 2
    while ($row -lt 6) {
        $cell = 1
        while ($cell -lt 5) {
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells($cell).Shape.TextFrame.TextRange.Text = ''
            $Cell ++
        }
        $row ++
    }

    $Counter = 1
    $RecomNumber = 1
    $row = 2
    foreach ($Impact in $HighImpact) {
        $LogHighImpact = $Impact.Values[0]
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 23 - Adding High Impact: ' + $LogHighImpact )
        if ($Counter -lt 14) {
            #Number
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(1).Shape.TextFrame.TextRange.Text = [string]$RecomNumber
            #Recommendation
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(2).Shape.TextFrame.TextRange.Text = $Impact.Values[0]
            #Service
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(3).Shape.TextFrame.TextRange.Text = $Impact.Values[1]
            #Impacted Resources
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(4).Shape.TextFrame.TextRange.Text = [string]$Impact.'Count'
            $counter ++
            $RecomNumber ++
            $row ++
        }
        else {
            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 23 - Adding new Slide..')
            $Counter = 1

            $Presentation.slides[$FirstSlide].Duplicate() | Out-Null

            $FirstSlide ++

            $NextSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $FirstSlide }

            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 23 - Cleaning table of new slide..')
            $rowTemp = 2
            while ($rowTemp -lt 15) {
                $cell = 1
                while ($cell -lt 5) {
                    ($NextSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($rowTemp).Cells($cell).Shape.TextFrame.TextRange.Text = ''
                    $Cell ++
                }
                $rowTemp ++
            }

            $CurrentSlide = $NextSlide

            $row = 2
            #Number
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(1).Shape.TextFrame.TextRange.Text = [string]$RecomNumber
            #Recommendation
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(2).Shape.TextFrame.TextRange.Text = $Impact.Values[0]
            #Service
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(3).Shape.TextFrame.TextRange.Text = $Impact.Values[1]
            #Impacted Resources
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(4).Shape.TextFrame.TextRange.Text = [string]$Impact.'Count'
            $Counter ++
            $RecomNumber ++
            $row ++
        }
    }
}

############# Slide 24
function Build-PPTSlide24 {
    Param($Presentation, $AUTOMESSAGE, $ImpactedResources)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 24 - Medium Impact Issues..')

    $MediumImpact = $ImpactedResources | Where-Object { $_.Impact -eq 'Medium' } | Group-Object -Property 'Recommendation Title', 'Resource Type' | Sort-Object -Property "Count" -Descending

    $FirstSlide = 24
    $TableID = 6
    $CurrentSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $FirstSlide }

    $TargetShape = ($CurrentSlide.Shapes | Where-Object { $_.Id -eq 41 })
    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 24 - Cleaning Table..')
    $row = 2
    while ($row -lt 6) {
        $cell = 1
        while ($cell -lt 5) {
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells($cell).Shape.TextFrame.TextRange.Text = ''
            $Cell ++
        }
        $row ++
    }

    $Counter = 1
    $RecomNumber = 1
    $row = 2
    foreach ($Impact in $MediumImpact) {
        $LogMediumImpact = $Impact.Values[0]
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 24 - Adding Medium Impact: ' + $LogMediumImpact)
        if ($Counter -lt 14) {
            #Number
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(1).Shape.TextFrame.TextRange.Text = [string]$RecomNumber
            #Recommendation
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(2).Shape.TextFrame.TextRange.Text = $Impact.Values[0]
            #Service
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(3).Shape.TextFrame.TextRange.Text = $Impact.Values[1]
            #Impacted Resources
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(4).Shape.TextFrame.TextRange.Text = [string]$Impact.'Count'
            $counter ++
            $RecomNumber ++
            $row ++
        }
        else {
            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 24 - Creating new slide..')
            $Counter = 1

            $Presentation.slides[$FirstSlide].Duplicate() | Out-Null

            $FirstSlide ++

            $NextSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $FirstSlide }

            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 24 - Cleaning Table of new slide..')
            $rowTemp = 2
            while ($rowTemp -lt 15) {
                $cell = 1
                while ($cell -lt 5) {
                    ($NextSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($rowTemp).Cells($cell).Shape.TextFrame.TextRange.Text = ''
                    $Cell ++
                }
                $rowTemp ++
            }

            $CurrentSlide = $NextSlide

            $row = 2
            #Number
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(1).Shape.TextFrame.TextRange.Text = [string]$RecomNumber
            #Recommendation
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(2).Shape.TextFrame.TextRange.Text = $Impact.Values[0]
            #Service
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(3).Shape.TextFrame.TextRange.Text = $Impact.Values[1]
            #Impacted Resources
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(4).Shape.TextFrame.TextRange.Text = [string]$Impact.'Count'
            $Counter ++
            $RecomNumber ++
            $row ++
        }
    }
}

############# Slide 25
function Build-PPTSlide25 {
    Param($Presentation, $AUTOMESSAGE, $ImpactedResources)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 25 - Low Impact Issues..')

    $LowImpact = $ImpactedResources | Where-Object { $_.Impact -eq 'Low' } | Group-Object -Property 'Recommendation Title', 'Resource Type' | Sort-Object -Property "Count" -Descending

    $FirstSlide = 25
    $TableID = 6
    $CurrentSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $FirstSlide }

    $TargetShape = ($CurrentSlide.Shapes | Where-Object { $_.Id -eq 41 })
    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 25 - Cleaning Table..')
    $row = 2
    while ($row -lt 6) {
        $cell = 1
        while ($cell -lt 5) {
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells($cell).Shape.TextFrame.TextRange.Text = ''
            $Cell ++
        }
        $row ++
    }

    $Counter = 1
    $RecomNumber = 1
    $row = 2
    foreach ($Impact in $LowImpact) {
        $LogLowImpact = $Impact.Values[0]
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 25 - Adding Low Impact: ' + $LogLowImpact)
        if ($Counter -lt 14) {
            #Number
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(1).Shape.TextFrame.TextRange.Text = [string]$RecomNumber
            #Recommendation
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(2).Shape.TextFrame.TextRange.Text = $Impact.Values[0]
            #Service
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(3).Shape.TextFrame.TextRange.Text = $Impact.Values[1]
            #Impacted Resources
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(4).Shape.TextFrame.TextRange.Text = [string]$Impact.'Count'
            $counter ++
            $RecomNumber ++
            $row ++
        }
        else {
            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 25 - Creating new Slide..')
            $Counter = 1

            $Presentation.slides[$FirstSlide].Duplicate() | Out-Null

            $FirstSlide ++

            $NextSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $FirstSlide }

            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 25 - Cleaning Table of new slide..')
            $rowTemp = 2
            while ($rowTemp -lt 15) {
                $cell = 1
                while ($cell -lt 5) {
                    ($NextSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($rowTemp).Cells($cell).Shape.TextFrame.TextRange.Text = ''
                    $Cell ++
                }
                $rowTemp ++
            }

            $CurrentSlide = $NextSlide

            $row = 2
            #Number
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(1).Shape.TextFrame.TextRange.Text = [string]$RecomNumber
            #Recommendation
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(2).Shape.TextFrame.TextRange.Text = $Impact.Values[0]
            #Service
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(3).Shape.TextFrame.TextRange.Text = $Impact.Values[1]
            #Impacted Resources
            ($CurrentSlide.Shapes | Where-Object { $_.Id -eq $TableID }).Table.Rows($row).Cells(4).Shape.TextFrame.TextRange.Text = [string]$Impact.'Count'
            $Counter ++
            $RecomNumber ++
            $row ++
        }
    }
}

############# Slide 28
function Build-PPTSlide28 {
    Param($Presentation, $AUTOMESSAGE, $PlatformIssues)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 28 - Recent Microsoft Outages..')

    $Loop = 1
    $CurrentSlide = 28

    if (![string]::IsNullOrEmpty($PlatformIssues)) {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 28 - Outages found..')
        foreach ($Outage in $PlatformIssues) {
            if (![string]::IsNullOrEmpty($Outage.title)) {
                if ($Loop -eq 1) {
                    $OutageName = ($Outage.'Tracking ID' + ' - ' + $Outage.title)
                    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 28 - Adding Outage: ' + $OutageName)

                    $OutageService = $Outage.'Impacted Service'

                    $SlidePlatformIssues = $Presentation.Slides | Where-Object { $_.SlideIndex -eq 28 }

                    $TargetShape = ($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 4 })
                    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

                    ($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = $OutageName

                    ($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(3).Text = $Outage.'What happened'

                    ($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(5).Text = $OutageService

                    ($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(7).Text = $Outage.'How can customers make incidents like this less impactful'

                    while (($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs().count -gt 7) {
                        ($SlidePlatformIssues.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(8).Delete()
                    }
                }
                else {
                    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 28 - Creating new Slide..')
                    ############### NEXT 9 SLIDES

                    $OutageName = ($Outage.'Tracking ID' + ' - ' + $Outage.title)
                    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 28 - Adding Outage: ' + $OutageName)

                    $OutageService = $Outage.'Impacted Service'

                    $Presentation.slides[$CurrentSlide].Duplicate() | Out-Null

                    $CurrentSlide ++

                    $NextSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $CurrentSlide }

                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = $OutageName

                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(3).Text = $Outage.'What happened'

                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(5).Text = $OutageService

                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(7).Text = $Outage.'How can customers make incidents like this less impactful'

                    while (($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs().count -gt 7) {
                        ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(8).Delete()
                    }
                }
                $Loop ++
            }
        }
    }
}

############# Slide 29
function Build-PPTSlide29 {
    Param($Presentation, $AUTOMESSAGE, $SupportTickets)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 29 - Sev-A Support Requests..')

    $Loop = 1
    $CurrentSlide = 29
    $Slide = 1

    # Prevents the script from creating the SupportTickets slide if there are no support tickets
    if (!($SupportTickets.count -eq 1 -and [string]::IsNullOrEmpty($SupportTickets.'Ticket ID'))) {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 29 - Support Tickets found..')
        foreach ($Tickets in $SupportTickets) {
            $TicketName = ($Tickets.'Ticket ID' + ' - ' + $Tickets.Title)
            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 29 - Adding Ticket: ' + $TicketName)
            $TicketStatus = $Tickets.'Status'
            $TicketDate = $Tickets.'Creation Date'

            if ($Slide -eq 1) {
                if ($Loop -eq 1) {
                    $SlideSupportRequests = $Presentation.Slides | Where-Object { $_.SlideIndex -eq 29 }
                    $TargetShape = ($SlideSupportRequests.Shapes | Where-Object { $_.Id -eq 4 })
                    $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

                    ($SlideSupportRequests.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = $TicketName
                    ($SlideSupportRequests.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(2).Text = "Status: $TicketStatus"
                    ($SlideSupportRequests.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(3).Text = "Creation Date: $TicketDate"

                    $Loop ++
                }
                else {
                    $newtextbox = ($SlideSupportRequests.Shapes | Where-Object { $_.Id -eq 7 }).Duplicate()

                    if ($Loop -eq 2) {
                        $newtextbox.name = 'Shape2'
                        $newtextbox.top = [int]$newtextbox.top + 100
                        $newtextbox.left = [int]$newtextbox.left - 10
                    }
                    elseif ($Loop -eq 3) {
                        $newtextbox.name = 'Shape3'
                        $newtextbox.top = [int]$newtextbox.top + 220
                        $newtextbox.left = [int]$newtextbox.left - 10
                    }

                    $newtextbox.TextFrame.TextRange.Paragraphs(1).Text = $TicketName
                    $newtextbox.TextFrame.TextRange.Paragraphs(2).Text = "Status: $TicketStatus"
                    $newtextbox.TextFrame.TextRange.Paragraphs(3).Text = "Creation Date: $TicketDate"

                    if ($Loop -eq 3) {
                        $Loop = 1
                        $Slide ++
                    }
                    else {
                        $Loop ++
                    }
                    Start-Sleep -Milliseconds 500
                }
            }
            else {
                if ($Loop -eq 1) {
                    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 29 - Adding new Slide..')

                    $Presentation.slides[$CurrentSlide].Duplicate() | Out-Null

                    $CurrentSlide ++

                    $NextSlide = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $CurrentSlide }

                    ($NextSlide.Shapes | Where-Object { $_.name -eq 'Shape2' }).Delete()
                    ($NextSlide.Shapes | Where-Object { $_.name -eq 'Shape3' }).Delete()

                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = $TicketName
                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(2).Text = "Status: $TicketStatus"
                    ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(3).Text = "Creation Date: $TicketDate"

                    $Loop ++
                }
                else {
                    $newtextbox = ($NextSlide.Shapes | Where-Object { $_.Id -eq 7 }).Duplicate()

                    if ($Loop -eq 2) {
                        $newtextbox.name = 'Shape2'
                        $newtextbox.top = [int]$newtextbox.top + 100
                        $newtextbox.left = [int]$newtextbox.left - 10
                    }
                    elseif ($Loop -eq 3) {
                        $newtextbox.name = 'Shape3'
                        $newtextbox.top = [int]$newtextbox.top + 220
                        $newtextbox.left = [int]$newtextbox.left - 10
                    }

                    $newtextbox.TextFrame.TextRange.Paragraphs(1).Text = $TicketName
                    $newtextbox.TextFrame.TextRange.Paragraphs(2).Text = "Status: $TicketStatus"
                    $newtextbox.TextFrame.TextRange.Paragraphs(3).Text = "Creation Date: $TicketDate"

                    if ($Loop -eq 3) {
                        $Loop = 1
                        $Slide ++
                    }
                    else {
                        $Loop ++
                    }
                }
            }
            Start-Sleep -Milliseconds 500
        }
    }
    else {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 29 - No Support Tickets found..')
        ($Presentation.Slides | Where-Object { $_.SlideIndex -eq 29 }).Delete()
    }
}

############# Slide 30
function Build-PPTSlide30 {
    Param($Presentation, $AUTOMESSAGE, $Retirements)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 30 - Service Retirement Notifications..')

    $Loop = 1
    $Spacer = 1
    $CurrentSlide = 30

    if (![string]::IsNullOrEmpty($Retirements)) {
        Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 30 - Service Retirement found..')
        $SlideRetirements = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $CurrentSlide }

        $TargetShape = ($SlideRetirements.Shapes | Where-Object { $_.Id -eq 4 })
        $TargetShape.TextFrame.TextRange.Text = $AUTOMESSAGE

        ($SlideRetirements.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = '.'

        foreach ($Retirement in $Retirements) {
            $RetireName = ($Retirement.'Retirement TrackingId' + ' - ' + $Retirement.'Recommendation Title')
            Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 30 - Adding Retirement: ' + $RetireName)
            if ($Loop -lt 11) {
                if ($Loop -eq 1) {
                    ($SlideRetirements.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = $RetireName
                    $Loop ++
                }
                else {
                    $NewShape = ($SlideRetirements.Shapes | Where-Object { $_.Id -eq 7 }).Duplicate()

                    $NewShape.name = ('Shape_' + $Loop)

                    $NewShape.top = [int]$NewShape.top + ($Spacer * 40)
                    $NewShape.left = [int]$NewShape.left - 10

                    $NewShape.TextFrame.TextRange.Paragraphs(1).Text = $RetireName

                    $Loop ++
                    $Spacer ++
                }
            }
            else {
                Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Editing Slide 30 - Creating new Slide..')
                $Loop = 1
                $Spacer = 1

                $Presentation.slides[$CurrentSlide].Duplicate() | Out-Null

                $CurrentSlide ++

                $SlideRetirements = $Presentation.Slides | Where-Object { $_.SlideIndex -eq $CurrentSlide }

                $ShapesToDelete = $SlideRetirements.Shapes | Where-Object { $_.Name -like 'Shape_*' }

                foreach ($Shape in $ShapesToDelete) {
                    $Shape.Delete()
                }

                ($SlideRetirements.Shapes | Where-Object { $_.Id -eq 7 }).TextFrame.TextRange.Paragraphs(1).Text = $RetireName
                $Loop ++
            }
        }
    }
}

######################## Assessment Findings Functions ##########################

function Initialize-ExcelImpactedResources {
    Param($ImpactedResources)

    $ImpactedResourcesFormatted = @()

    ForEach ($Resource in $ImpactedResources) {
        $obj = @{
            'Impacted?'                 = 'Yes';
            'Resource Type'             = $Resource.'Resource Type';
            'subscriptionId'            = $Resource.subscriptionId;
            'resourceGroup'             = $Resource.resourceGroup;
            'location'                  = $Resource.location;
            'name'                      = $Resource.name;
            'id'                        = $Resource.id;
            'custom1'                   = $Resource.custom1;
            'custom2'                   = $Resource.custom2;
            'custom3'                   = $Resource.custom3;
            'custom4'                   = $Resource.custom4;
            'custom5'                   = $Resource.custom5;
            'Recommendation Title'      = $Resource.'Recommendation Title';
            'Impact'                    = $Resource.Impact;
            'Recommendation Control'    = $Resource.'Recommendation Control';
            'Potential Benefit'         = $Resource.'Potential Benefit';
            'Learn More Link'           = $Resource.'Learn More Link';
            'Long Description'          = $Resource.'Long Description';
            'Guid'                      = $Resource.Guid;
            'Category'                  = $Resource.Category;
            'Source'                    = $Resource.'Source';
            'WAF Pillar'                = $Resource.'WAF Pillar';
            'Platform Issue TrackingId' = $Resource.'Platform Issue TrackingId';
            'Retirement TrackingId'     = $Resource.'Retirement TrackingId';
            'Support Request Number'    = $Resource.'Support Request Number';
            'Notes'                     = $Resource.Notes;
            'checkName'                 = $Resource.checkName
        }
        $ImpactedResourcesFormatted += $obj
    }

    # Returns the array with all the recommendations already formatted to be exported to Excel
    return $ImpactedResourcesFormatted
}

function Export-ExcelImpactedResources {
    Param($ImpactedResourcesFormatted)

    $Style = @()
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range A:F
    $Style += New-ExcelStyle -HorizontalAlignment Left -Range G:G
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range G12:G12
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range H:L
    $Style += New-ExcelStyle -HorizontalAlignment Center -WrapText -Range M:M
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range N:N
    $Style += New-ExcelStyle -HorizontalAlignment Center -WrapText -Range O:O
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range P:Q
    $Style += New-ExcelStyle -HorizontalAlignment Center -WrapText -Range R:R
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range S:AA

    $ImpactedResourcesSheet = New-Object System.Collections.Generic.List[System.Object]
    $ImpactedResourcesSheet.Add('Impacted?')
    $ImpactedResourcesSheet.Add('Resource Type')
    $ImpactedResourcesSheet.Add('subscriptionId')
    $ImpactedResourcesSheet.Add('resourceGroup')
    $ImpactedResourcesSheet.Add('location')
    $ImpactedResourcesSheet.Add('name')
    $ImpactedResourcesSheet.Add('id')
    $ImpactedResourcesSheet.Add('custom1')
    $ImpactedResourcesSheet.Add('custom2')
    $ImpactedResourcesSheet.Add('custom3')
    $ImpactedResourcesSheet.Add('custom4')
    $ImpactedResourcesSheet.Add('custom5')
    $ImpactedResourcesSheet.Add('Recommendation Title')
    $ImpactedResourcesSheet.Add('Impact')
    $ImpactedResourcesSheet.Add('Recommendation Control')
    $ImpactedResourcesSheet.Add('Potential Benefit')
    $ImpactedResourcesSheet.Add('Learn More Link')
    $ImpactedResourcesSheet.Add('Long Description')
    $ImpactedResourcesSheet.Add('Guid')
    $ImpactedResourcesSheet.Add('Category')
    $ImpactedResourcesSheet.Add('Source')
    $ImpactedResourcesSheet.Add('WAF Pillar')
    $ImpactedResourcesSheet.Add('Platform Issue TrackingId')
    $ImpactedResourcesSheet.Add('Retirement TrackingId')
    $ImpactedResourcesSheet.Add('Support Request Number')
    $ImpactedResourcesSheet.Add('Notes')
    $ImpactedResourcesSheet.Add('checkName')

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Exporting Impacted Resources to Excel')
    $ImpactedResourcesFormatted | ForEach-Object { [PSCustomObject]$_ } | Select-Object $ImpactedResourcesSheet |
    Export-Excel -Path $NewAssessmentFindingsFile -WorksheetName '3.ImpactedResources' -TableName 'impactedresources' -TableStyle $TableStyle -Style $Style -StartRow 12
}

function Initialize-ExcelRecommendations {
    Param($ImpactedResources)

    $RecommendationsFormatted = @()

    $GroupedResources = $ImpactedResources.where({ ![String]::IsNullOrEmpty($_.Guid) }) | Group-Object -Property 'Guid' | Sort-Object -Property 'Count' -Descending

    $CustomRecommendations = $ImpactedResources.where({ [String]::IsNullOrEmpty($_.Guid) })

    ForEach ($Resource in $GroupedResources) {

        $Recommendation = $ImpactedResources | Where-Object { $_.Guid -eq $Resource.Name } | Select-Object -First 1

        $obj = @{
            'Impact'                 = $Recommendation.Impact;
            'Description'            = $Recommendation.'Recommendation Title';
            'Potential Benefit'      = $Recommendation.'Potential Benefit';
            'Impacted Resources'     = $Resource.Count;
            'Resource Type'          = $Recommendation.'Resource Type';
            'Recommendation Control' = $Recommendation.'Recommendation Control';
            'Long Description'       = $Recommendation.'Long Description';
            'Category'               = $Recommendation.Category;
            'Learn More Link'        = $Recommendation.'Learn More Link';
            'Guid'                   = $Recommendation.Guid;
            'Notes'                  = $Recommendation.Notes;
        }
        $RecommendationsFormatted += $obj
    }

    $CustomRecommendations.Foreach(
        {
            $obj = @{
                'Impact'                 = $_.Impact;
                'Description'            = $_.'Recommendation Title'
                'Potential Benefit'      = $_.'Potential Benefit';
                'Impacted Resources'     = 1;
                'Resource Type'          = $_.'Resource Type';
                'Recommendation Control' = $_.'Recommendation Control';
                'Long Description'       = $_.'Long Description';
                'Category'               = $_.Category;
                'Learn More Link'        = $_.'Learn More Link';
                'Guid'                   = $_.Guid;
                'Notes'                  = $_.Notes;
            }
            $RecommendationsFormatted += $obj
        }
    )

    # Returns the array with all the recommendations already formatted to be exported to Excel
    return $RecommendationsFormatted
}

function Export-ExcelRecommendations {
    Param($RecommendationsFormatted)

    $Style = @()
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range A:A
    $Style += New-ExcelStyle -HorizontalAlignment Left -Range B:C
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range B11:C11
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range D:D
    $Style += New-ExcelStyle -HorizontalAlignment Left -Range E:E
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range E11:E11
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range F:F
    $Style += New-ExcelStyle -HorizontalAlignment Left -WrapText -Range G:G
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range G11:G11
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range H:H
    $Style += New-ExcelStyle -HorizontalAlignment Left -Range I:I
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range I11:I11
    $Style += New-ExcelStyle -HorizontalAlignment Center -Range J:K
    $Style += New-ExcelStyle -Range A11:K11 -FontColor White

    $RecommendationSheet = New-Object System.Collections.Generic.List[System.Object]
    $RecommendationSheet.Add('Impact')
    $RecommendationSheet.Add('Description')
    $RecommendationSheet.Add('Potential Benefit')
    $RecommendationSheet.Add('Impacted Resources')
    $RecommendationSheet.Add('Resource Type')
    $RecommendationSheet.Add('Recommendation Control')
    $RecommendationSheet.Add('Long Description')
    $RecommendationSheet.Add('Category')
    $RecommendationSheet.Add('Learn More Link')
    $RecommendationSheet.Add('Guid')
    $RecommendationSheet.Add('Notes')

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Exporting Recommendations to Excel')
    $RecommendationsFormatted | ForEach-Object { [PSCustomObject]$_ } | Select-Object $RecommendationSheet |
    Export-Excel -Path $NewAssessmentFindingsFile -WorksheetName '2.Recommendations' -TableName 'recommendationT' -TableStyle $TableStyle -Style $Style -StartRow 11
}

function Export-ExcelWorkloadInventory {
    Param($ExcelWorkloadInventory)

    $Style = @()
    $Style += New-ExcelStyle -HorizontalAlignment Center

    $WorkloadSheet = New-Object System.Collections.Generic.List[System.Object]
    $WorkloadSheet.Add('id')
    $WorkloadSheet.Add('name')
    $WorkloadSheet.Add('type')
    $WorkloadSheet.Add('tenantId')
    $WorkloadSheet.Add('kind')
    $WorkloadSheet.Add('location')
    $WorkloadSheet.Add('resourceGroup')
    $WorkloadSheet.Add('subscriptionId')
    $WorkloadSheet.Add('managedBy')
    $WorkloadSheet.Add('sku')
    $WorkloadSheet.Add('plan')
    $WorkloadSheet.Add('zones')

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Exporting Workload Inventory to Excel')
    $ExcelWorkloadInventory | ForEach-Object { [PSCustomObject]$_ } | Select-Object $WorkloadSheet |
    Export-Excel -Path $NewAssessmentFindingsFile -WorksheetName '6.WorkloadInventory' -TableName 'WorkloadResources' -TableStyle $TableStyle -Style $Style -StartRow 12
}

function Build-ExcelPivotTable {
    Param($NewAssessmentFindingsFile)

    # Open the Excel file to add the Pivot Tables and Charts
    $Excel = Open-ExcelPackage -Path $NewAssessmentFindingsFile

    $Address = $Excel.'2.Recommendations'.Tables[0].Address.Address

    $PTParams = @{
        PivotTableName    = 'P0'
        Address           = $Excel.'7.PivotTable'.cells['A3']
        SourceWorkSheet   = $Excel."2.Recommendations"
        SourceRange       = $Address
        PivotRows         = @('Resource Type')
        PivotColumns      = @('Impact')
        PivotData         = @{'Resource Type' = 'Count' }
        PivotTableStyle   = 'Medium9'
        Activate          = $true
        PivotFilter       = 'Category'
        ShowPercent       = $false
        IncludePivotChart = $false
    }
    Add-PivotTable @PTParams

    $PTParams = @{
        PivotTableName    = 'P1'
        Address           = $Excel.'7.PivotTable'.cells['H3']
        SourceWorkSheet   = $Excel."2.Recommendations"
        SourceRange       = $Address
        PivotRows         = @('Recommendation Control')
        PivotColumns      = @('Impact')
        PivotData         = @{'Resource Type' = 'Count' }
        PivotTableStyle   = 'Medium9'
        Activate          = $true
        PivotFilter       = 'Resource Type'
        ShowPercent       = $false
        IncludePivotChart = $false
    }
    Add-PivotTable @PTParams

    $PTParams = @{
        PivotTableName    = 'P2'
        Address           = $Excel.'7.PivotTable'.cells['O3']
        SourceWorkSheet   = $Excel."2.Recommendations"
        SourceRange       = $Address
        PivotRows         = @('Impact')
        PivotData         = @{'Impacted Resources' = 'Sum' }
        PivotTableStyle   = 'Medium9'
        Activate          = $true
        ShowPercent       = $false
        IncludePivotChart = $false
    }
    Add-PivotTable @PTParams

    $PTParams = @{
        PivotTableName    = 'P3'
        Address           = $Excel.'7.PivotTable'.cells['S3']
        SourceWorkSheet   = $Excel."2.Recommendations"
        SourceRange       = $Address
        PivotRows         = @('Impact')
        PivotData         = @{'Guid' = 'Count' }
        PivotTableStyle   = 'Medium10'
        Activate          = $true
        ShowPercent       = $false
        IncludePivotChart = $false
    }
    Add-PivotTable @PTParams

    return $Excel
}

function Build-ExcelPivotChart {
    Param($Excel)

    $ChartP0 = $Excel."1.Dashboard".Drawings.AddChart('ChartP0', 'BarClustered', $Excel."7.PivotTable".PivotTables['P0'])
    $ChartP0.SetSize(600, 700)
    $ChartP0.SetPosition(18, 10, .5, 90)
    $ChartP0.fill.color = [System.Drawing.Color]::FromArgb(255, 194, 194, 194)
    $ChartP0.PlotArea.fill.color = [System.Drawing.Color]::FromArgb(255, 194, 194, 194)
    $ChartP0.RoundedCorners = $true
    $ChartP0.Legend.Position = 'Top'
    #$ChartP0.DisplayBlanksAs = 'Gap'

    $ChartP0.Title.Font.Bold = $true
    $ChartP0.Title.Font.SetFromFont("Segoe UI")
    $ChartP0.Title.Font.Size = 11
    $ChartP0.Title.Text = 'Recommendations by Impact per ResourceType'

    $ChartP0.XAxis.Title.Font.SetFromFont('Segoe UI')
    $ChartP0.XAxis.Title.Font.Size = 9
    $ChartP0.XAxis.MinorTickMark = "None"
    $ChartP0.XAxis.MajorTickMark = "None"

    $ChartP0.YAxis.Title.Font.SetFromFont('Segoe UI')
    $ChartP0.YAxis.Title.Font.Size = 9
    $ChartP0.YAxis.MinorTickMark = "None"
    $ChartP0.YAxis.MajorTickMark = "None"

    $ChartP1 = $Excel."1.Dashboard".Drawings.AddChart('ChartP1', 'BarClustered', $Excel."7.PivotTable".PivotTables['P1'])
    $ChartP1.SetSize(500, 700)
    $ChartP1.SetPosition(18, 10, 6, 75)
    $ChartP1.fill.color = [System.Drawing.Color]::FromArgb(255, 194, 194, 194)
    $ChartP1.PlotArea.fill.color = [System.Drawing.Color]::FromArgb(255, 194, 194, 194)
    $ChartP1.RoundedCorners = $true
    $ChartP1.Legend.Position = 'Top'
    #$ChartP1.DisplayBlanksAs = 'Gap'

    $ChartP1.Title.Font.Bold = $true
    $ChartP1.Title.Font.SetFromFont("Segoe UI")
    $ChartP1.Title.Font.Size = 11
    $ChartP1.Title.Text = 'Recommendations by Impact per Category'

    $ChartP1.XAxis.Title.Font.SetFromFont('Segoe UI')
    $ChartP1.XAxis.Title.Font.Size = 9
    $ChartP1.XAxis.MinorTickMark = "None"

    $ChartP1.YAxis.Title.Font.SetFromFont('Segoe UI')
    $ChartP1.YAxis.Title.Font.Size = 9
    $ChartP1.YAxis.MinorTickMark = "None"

    Close-ExcelPackage $Excel
}

# Start the stopwatch to time the script
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#Call the functions
$Version = "2.1.5"
Write-Host "Version: " -NoNewline
Write-Host $Version -ForegroundColor DarkBlue -NoNewline
Write-Host " "

$CoreFile = get-item -Path $ExpertAnalysisFile
$CoreFile = $CoreFile.FullName

Test-ReviewedRecommendations -ExcelFile $CoreFile

Write-Debug (' ---------------------------------- STARTING REPORT GENERATOR SCRIPT --------------------------------------- ')
Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Starting Report Generator Script..')
Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Script Version: ' + $Version)
Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Excel File: ' + $ExpertAnalysisFile)
$ImportExcel = Get-Module -Name ImportExcel -ListAvailable -ErrorAction silentlycontinue
foreach ($IExcel in $ImportExcel) {
    $IExcelPath = $IExcel.Path
    $IExcelVer = [string]$IExcel.Version
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - ImportExcel Module Path: ' + $IExcelPath)
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - ImportExcel Module Version: ' + $IExcelVer)
}

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "10% Complete." -PercentComplete 10
Test-Requirement
Write-Progress -Id 1 -activity "Processing Office Apps" -Status "15% Complete." -PercentComplete 15
#Set-LocalFile
Write-Progress -Id 1 -activity "Processing Office Apps" -Status "20% Complete." -PercentComplete 20

$ExcelImpactedResources = Get-ExcelImpactedResources -ExcelFile $CoreFile

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "25% Complete." -PercentComplete 25

$ExcelPlatformIssues = Get-ExcelPlatformIssues -ExcelFile $CoreFile

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "30% Complete." -PercentComplete 30

$ExcelSupportTickets = Get-ExcelSupportTicket -ExcelFile $CoreFile

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "35% Complete." -PercentComplete 35

$ExcelWorkloadInventory = Get-ExcelWorkloadInventory -ExcelFile $CoreFile

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "40% Complete." -PercentComplete 40

$ExcelRetirements = Get-ExcelRetirement -ExcelFile $CoreFile

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "45% Complete." -PercentComplete 45


$PPTFinalFile = New-PPTFile -PPTTemplateFile $pptTemplateFilePath  # NEED FIX: PPTTemplateFile parameter does not use in the function
Write-Host "PowerPoint" -ForegroundColor DarkRed -NoNewline
Write-Host " and " -NoNewline
Write-Host "Excel" -ForegroundColor DarkGreen -NoNewline
Write-Host " "
Write-Host "Editing " -NoNewline
$NewAssessmentFindingsFile = New-AssessmentFindingsFile -AssessmentFindingsFile $assessmentFindingsFilePath


$AUTOMESSAGE = 'AUTOMATICALLY MODIFIED (Please Review)'

Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Getting Resource Types..')

$TempImpactedResources = $ExcelImpactedResources | Select-Object -Property 'Resource Type', 'id' -Unique

$ResourcesTypes = $TempImpactedResources | Group-Object -Property 'Resource Type' | Sort-Object -Property 'Count' -Descending | Select-Object -First 10

Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Starting to Process Assessment Findings..')

$ImpactedResourcesFormatted = Initialize-ExcelImpactedResources -ImpactedResources $ExcelImpactedResources
Export-ExcelImpactedResources -ImpactedResourcesFormatted $ImpactedResourcesFormatted

$RecommendationsFormatted = Initialize-ExcelRecommendations -ImpactedResources $ExcelImpactedResources
Export-ExcelRecommendations -RecommendationsFormatted $RecommendationsFormatted

Export-ExcelWorkloadInventory -ExcelWorkloadInventory $ExcelWorkloadInventory

$ExcelFileLive = Build-ExcelPivotTable -NewAssessmentFindingsFile $NewAssessmentFindingsFile

Build-ExcelPivotChart -Excel $ExcelFileLive

try {
    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Starting PowerPoint..')
    # Openning PPT
    try {
        $Application = New-Object -ComObject PowerPoint.Application
        $Presentation = $Application.Presentations.Open($pptTemplateFilePath, $null, $null, $null)
    }
    catch {
        Write-Host ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + "- Error: " + $_.Exception.Message)
        Get-Process -Name "POWERPNT" -ErrorAction Ignore | Where-Object { $_.CommandLine -like '*/automation*' } | Stop-Process -Force
    }

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Starting Excel..')
    # Openning Excel
    try {
        $ExcelApplication = New-Object -ComObject Excel.Application
        Start-Sleep -Milliseconds 500
        $ExcelWorkbooks = $ExcelApplication.Workbooks.Open($NewAssessmentFindingsFile)
    }
    catch {
        Write-Host ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + "- Error: " + $_.Exception.Message)
        Get-Process -Name "excel" -ErrorAction Ignore | Where-Object { $_.CommandLine -like '*/automation*' } | Stop-Process -Force
    }

    Remove-PPTSlide1 -Presentation $Presentation -CustomerName $CustomerName -WorkloadName $WorkloadName
    Build-PPTSlide12 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -WorkloadName $WorkloadName -ResourcesType $ResourcesTypes
    Build-PPTSlide16 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -ImpactedResources $ExcelImpactedResources

    while ([string]::IsNullOrEmpty($ExcelWorkbooks)) {
        Start-Sleep 1
    }

    Build-PPTSlide17 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -ExcelWorkbooks $ExcelWorkbooks

    Build-PPTSlide30 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -Retirements $ExcelRetirements

    Build-PPTSlide29 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -SupportTickets $ExcelSupportTickets

    Build-PPTSlide28 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -PlatformIssues $ExcelPlatformIssues

    Build-PPTSlide25 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -ImpactedResources $ExcelImpactedResources
    Build-PPTSlide24 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -ImpactedResources $ExcelImpactedResources
    Build-PPTSlide23 -Presentation $Presentation -AUTOMESSAGE $AUTOMESSAGE -ImpactedResources $ExcelImpactedResources

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Closing Excel..')
    $ExcelWorkbooks.Save()
    $ExcelWorkbooks.Close()
    $ExcelApplication.Quit()

    Write-Debug ((get-date -Format 'yyyy-MM-dd HH:mm:ss') + ' - Closing PowerPoint..')
    $Presentation.SaveAs($PPTFinalFile)
    $Presentation.Close()
    $Application.Quit()

    #if ($csvExport.IsPresent) {
    $WorkloadRecommendationTemplate = Build-SummaryActionPlan -ImpactedResources $ExcelImpactedResources -includeLow $includeLow

    $CSVFile = ("$PWD\Impacted Resources and Recommendations Template " + (get-date -Format "yyyy-MM-dd-HH-mm") + '.csv')

    $WorkloadRecommendationTemplate | Export-Csv -Path $CSVFile
    #}
}
finally {
    # Stop the PowerPoint and Excel automation processes if they are still running.
    Get-Process -Name 'EXCEL','POWERPNT' -ErrorAction Ignore |
    Where-Object { $_.CommandLine -like '*/automation*' } |
    ForEach-Object {
        Write-Debug ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + (' - Trying to kill process {0} (PID:{1}).' -f $_.Name, $_.Id))
        $_ | Stop-Process -Force
    }
}

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "90% Complete." -PercentComplete 90

Write-Progress -Id 1 -activity "Processing Office Apps" -Status "100% Complete." -Completed

$stopwatch.Stop()

################ Finishing

Write-Host "---------------------------------------------------------------------"
Write-Host ('Execution Complete. Total Runtime was: ') -NoNewline
Write-Host $stopwatch.Elapsed.toString('hh\:mm\:ss') -ForegroundColor Cyan
Write-Host 'PowerPoint File Saved as: ' -NoNewline
Write-Host $PPTFinalFile -ForegroundColor Cyan
Write-Host 'Assessment Findings File Saved as: ' -NoNewline
Write-Host $NewAssessmentFindingsFile -ForegroundColor Cyan

#if ($csvExport.IsPresent) {
Write-Host 'CSV File Saved as: ' -NoNewline
Write-Host $CSVFile -ForegroundColor Cyan
#}

Write-Host "---------------------------------------------------------------------"
