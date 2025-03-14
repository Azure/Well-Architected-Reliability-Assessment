[![RunPesterTests](https://github.com/Azure/Well-Architected-Reliability-Assessment/actions/workflows/pestertests.yml/badge.svg)](https://github.com/Azure/Well-Architected-Reliability-Assessment/actions/workflows/pestertests.yml)
[![PSScriptAnalyzer](https://github.com/Azure/Well-Architected-Reliability-Assessment/actions/workflows/powershell.yml/badge.svg)](https://github.com/Azure/Well-Architected-Reliability-Assessment/actions/workflows/powershell.yml)

> [!NOTE]
> This project is currently under development. The information in this README is subject to change.

# Well-Architected-Reliability-Assessment

The Well-Architected Reliability Assessment is aimed to assess an Azure workload implementation across the reliability pillar of the Microsoft Azure Well-Architected Framework. A workload is a resource or collection of resources that provide end-to-end functionality to one or multiple clients (humans or systems). An application can have multiple workloads, with multiple APIs and databases working together to deliver specific functionality.

The main goal of the Well-Architected Reliability Assessment is to provide an in-depth and comprehensive end-to-end Architecture and Resources review of an existing Workload to identify critical reliability, resiliency, availability, and recovery risks to the scoped workload on Azure.

This repository holds scripts and automation built for the Well-Architected Reliability Assessment and is currently under development.

## Table of Contents

- [Patch Notes](#patch-notes)
- [Getting Started](#getting-started)
  - [Quick Workflow Example](#quick-workflow-example)
- [Requirements](#requirements)
- [Quick Starts](#quick-starts)
  - [Start-WARACollector](#start-waracollector)
  - [Start-WARAAnalyzer](#start-waraanalyzer)
  - [Start-WARAReport](#start-warareport)
- [Project Structure](#project-structure)
- [Modules](#modules)

## Getting Started

### Patch Notes

- **Version 0.0.21**
  - Fixes issue with Start-WARACollector not running when -ConfigFile was being passed due to added parameter set on the ConfigFile parameter.
  - Added tests for parameter set testing to prevent this from happening again.

- **Version 0.0.20**
  - Fixes performance issue with Get-WAFFilteredResources.
    - The function was not optimized for performance and was spending too much time processing scope. This has been fixed by changing how we filter resources. The function now uses Sort-Object | Get-Unique -AsString to filter resources and resulted in a significant performance improvement. The function now runs in a few milliseconds compared to a few minutes when collections were greater than 10,000 resources.
  - Fixes issue with empty rows appearing in the Excel Assessment findings report.
  - Improves the module version check message.
  - Adds support for custom recommendations to the Expert Analysis Spreadsheet.
    - The process documentation for this will be added soon.
  - Add AI-GPT-RAG support to the Collector and Analyzer modules.
    - This enables the flag -AI_GPT_RAG on the collector script to capture specialized workload data for AI workloads.

- **Version 0.0.19**
  - Added clipboard history check to temporarily resolve issue with Start-WARAReport failing due to legacy code that uses copy() paste() to duplicate tables in the PowerPoint report.
    - If clipboard history is enabled on the machine, the Start-WARAReport cmdlet will throw an error and exit. This is a temporary workaround until the legacy code is updated to use the built-in duplicate() method for the slide in powerpoint.

- **Version 0.0.18**
  - Fixes issue with Start-WARAAnalyzer creating an excel file that cannot be loaded into Start-WARAReport.

- **Version 0.0.17**
  - Fixes issue with worksheets 3. and 4. not populating from the correct data source in the Collector output.

- **Version 0.0.16**
  - Fixes issue with Start-WARAReport not running due to empty rows in an excel file.
  - Applies data validation rules to 4.ImpactedResourcesAnalysis worksheet for 'REQUIRED ACTIONS / REVIEW STATUS' column.
    - Data validation rule is set to error if cell contents are not equal to Reviewed or Pending. This ensures that there are no entry issues with the excel column.

- **Version 0.0.15**
  - Fixed a bug that caused the Start-WARAAnalyzer cmdlet to fail when Azure retirements was empty in the JSON file.
    - [#88](https://github.com/Azure/Well-Architected-Reliability-Assessment/issues/88)

- **Version 0.0.14**
  - Initial release of the Well-Architected Reliability Assessment module.
  - Added the Start-WARACollector cmdlet.
  - Added the Start-WARAAnalyzer cmdlet.
    - Added the new Excel Analysis template.
  - Added the Start-WARAReport cmdlet.
    - Added the new Excel Report template.
  - Added the WARA module.
  - Added the Advisor module.
  - Added the Collector module.
  - Added the Outage module.
  - Added the Retirement module.
  - Added the Scope module.
  - Added the ServiceHealth module.
  - Added the Support module.
  - Added the Utils module.

### WARA Module Flow Architecture

```mermaid
flowchart TD
    Start[User installs WARA module] -->|Import-Module WARA| ModuleLoaded
    ModuleLoaded --> Collector

    subgraph "WARA Workflow"
    Collector[Start-WARACollector] -->|Outputs JSON file| CollectorOutput[(JSON file)]
    CollectorOutput --> Analyzer[Start-WARAAnalyzer]
    Analyzer -->|Processes data & outputs Excel| AnalyzerOutput[(Excel Action Plan)]
    AnalyzerOutput --> Reporter[Start-WARAReport]
    Reporter -->|Creates final reports| FinalOutput[PowerPoint & Excel Reports]
    end
```

### Quick Workflow Example

```PowerShell
# Assume we running from a C:\WARA directory

# Installs the WARA module from the PowerShell Gallery.
Install-Module WARA

# Imports the WARA module to the PowerShell session.
Import-Module WARA

# Start the WARA collector.
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000"

# Assume output from collector is 'C:\WARA\WARA_File_2024-04-01_10_01.json'
Start-WARAAnalyzer -JSONFile 'C:\WARA\WARA_File_2024-04-01_10_01.json'

# Assume output from analyzer is 'C:\WARA\Expert-Analysis-v1-2025-02-04-11-14.xlsx'
Start-WARAReport -ExpertAnalysisFile 'C:\WARA\Expert-Analysis-v1-2025-02-04-11-14.xlsx'

#You will now have your PowerPoint and Excel reports generated under the C:\WARA directory.
```

## Requirements

> [!IMPORTANT]
> These are the requirements for the collector. Requirements for the analyzer and report will be added in the future.

- [PowerShell 7.4](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- Azure PowerShell Module
  - If you don't have the Azure PowerShell module installed, you can install it by running the following command:

    ```powershell
    Install-Module -Name Az
     ```

  - If you have the Azure PowerShell module installed, you can update it by running the following command:

    ```powershell
    Update-Module -Name Az
    ```

- Az.Accounts PowerShell Module 3.0 or later
  - If you don't have the Az.Accounts module installed, you can install it by running the following command:

    ```powershell
    Install-Module -Name Az.Accounts
    ```

  - If you have the Az.Accounts module installed, you can update it by running the following command:

    ```powershell
    Update-Module -Name Az.Accounts
    ```

- Az.ResourceGraph PowerShell Module 1.0 or later
  - If you don't have the Az.ResourceGraph module installed, you can install it by running the following command:

    ```powershell
    Install-Module -Name Az.ResourceGraph
    ```

  - If you have the Az.ResourceGraph module installed, you can update it by running the following command:

    ```powershell
    Update-Module -Name Az.ResourceGraph
    ```

## Quick Starts

### Start-WARACollector

These instructions are the same for any platform that supports PowerShell. The following instructions have been tested on Azure Cloud Shell, Windows, and Linux.

You can review all of the parameters on the Start-WARACollector [here](docs/wara/Start-WARACollector.md).

> [!NOTE]
> Whatever directory you run the `Start-WARACollector` cmdlet in, the Excel file will be created in that directory. For example: if you run the `Start-WARACollector` cmdlet in the `C:\Temp` directory, the Excel file will be created in the `C:\Temp` directory.

1. Install the WARA module from the PowerShell Gallery.

```powershell
# Installs the WARA module from the PowerShell Gallery.
Install-Module WARA
```

2. Import the WARA module.

```powershell
# Import the WARA module.
Import-Module WARA
```

3. Start the WARA collector. (Replace these values with your own)

```powershell
# Start the WARA collector.
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000"
```

### Examples

#### Run the collector against a specific subscription

```PowerShell
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000"
```

#### Run the collector against a multiple specific subscriptions

```PowerShell
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds @("/subscriptions/00000000-0000-0000-0000-000000000000","/subscriptions/00000000-0000-0000-0000-000000000001")
```

#### Run the collector against a specific subscription and resource group

```PowerShell
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000" -ResourceGroups "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-001"
```

#### Run the collector against a specific subscription and resource group and filtering by tag key/values

```PowerShell
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000" -ResourceGroups "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-001" -Tags "Env||Environment!~Dev||QA" -AVD -SAP -HPC
```

#### Run the collector against a specific subscription and resource group, filtering by tag key/values and using the specialized resource types (AVD, SAP, HPC, AVS)

```PowerShell
Start-WARACollector -TenantID "00000000-0000-0000-0000-000000000000" -SubscriptionIds "/subscriptions/00000000-0000-0000-0000-000000000000" -ResourceGroups "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-001" -Tags "Env||Environment!~Dev||QA" -AVD -SAP -HPC
```

#### Run the collector using a configuration file

```PowerShell
Start-WARACollector -ConfigFile "C:\path\to\config.txt"
```

#### Run the collector using a configuration file and using the specialized resource types (AVD, SAP, HPC, AVS)

```PowerShell
Start-WARACollector -ConfigFile "C:\path\to\config.txt" -SAP -AVD
```

### Start-WARAAnalyzer

The `Start-WARAAnalyzer` cmdlet is used to analyze the collected data and generate the core WARA Action Plan Excel file.

> [!NOTE]
> Whatever directory you run the `Start-WARAAnalyzer` cmdlet in, the Excel file will be created in that directory. For example: if you run the `Start-WARAAnalyzer` cmdlet in the `C:\Temp` directory, the Excel file will be created in the `C:\Temp` directory.

You can review all of the parameters of Start-WARAAnalyzer [here](docs/wara/Start-WARAAnalyzer.md).

#### Examples

##### Run the analyzer against a specific JSON file

```PowerShell
Start-WARAAnalyzer -JSONFile 'C:\WARA\WARA_File_2024-04-01_10_01.json'
```

### Start-WARAReport

The `Start-WARAReport` cmdlet is used to generate the WARA reports.

> [!NOTE]
> Whatever directory you run the `Start-WARAReport` cmdlet in, the Excel and PowerPoint files will be created in that directory. For example: if you run the `Start-WARAReport` cmdlet in the `C:\Temp` directory, the Excel and PowerPoint files will be created in the `C:\Temp` directory.

You can review all of the parameters of Start-WARAReport [here](docs/wara/Start-WARAReport.md).

#### Examples

##### Create the Excel and PowerPoint reports from the Action Plan Excel output

```PowerShell
Start-WARAReport -ExpertAnalysisFile 'C:\WARA\Expert-Analysis-v1-2025-02-04-11-14.xlsx'
```

## Project Structure

This repository is meant to be used for the development of the Well-Architected Reliability Assessment automation. This project uses outputs from the Azure Well-Architected Framework and Azure Advisor to provide insights into the reliability of an Azure workload.

## Modules

- [🔍wara](docs/wara/wara.md)
- [🎗️advisor](docs/advisor/advisor.md)
- [📦collector](docs/collector/collector.md)
- [🌩️outage](docs/outage/outage.md)
- [🏖️retirement](docs/retirement/retirement.md)
- [🔬scope](docs/scope/scope.md)
- [🏥servicehealth](docs/servicehealth/servicehealth.md)
- [🩹support](docs/support/support.md)
- [🔧utils](docs/utils/utils.md)
