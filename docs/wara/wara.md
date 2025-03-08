# WARA Module

## Description

This module contains the functions and classes required for the Well Architected Reliability Review Automation (WARA) project.

## WARA Cmdlets

### [Start-WARACollector](Start-WARACollector.md)

This is the main cmdlet that starts the WARA collector. It collects the data from a variety of sources and exports it to a json file.

### [Start-WARAAnalyzer](Start-WARAAnalyzer.md)

This is the main cmdlet that starts the WARA analyzer. It processes the json file created by the `Start-WARACollector` function and creates the core WARA Action Plan Excel file.

### [Start-WARAReport](Start-WARAReport.md)

This is the main cmdlet that starts the WARA report. It processes the json file created by the `Start-WARACollector` function and creates the report documentation.

### Detailed Component Flow

```mermaid
flowchart TB
  subgraph Collector [Start-WARACollector]
    direction LR
    C1[Connect to Azure] --> C2[Gather Resources] --> C3[Process Inventory] --> C4[Get Recommendations] --> C5[Process Health Data] --> COut[JSON Output]
  end

  subgraph Analyzer [Start-WARAAnalyzer]
    direction LR
    A1[Read JSON] --> A2[Process Recommendations] --> A3[Calculate Impacts] --> A4[Determine Actions] --> AOut[Excel Action Plan]
  end

  subgraph Reporter [Start-WARAReport]
    direction LR
    R1[Read Excel] --> R2[Process Findings] --> R3[Generate Charts] --> R4[Create Documents] --> ROut[PowerPoint & Word]
  end

  Collector --> Analyzer
  Analyzer --> Reporter
```

## [WARA Classes](wara-module-classes.md)

- [aprlResourceTypeObj](wara-module-classes.md#aprlresourcetypeobj) - Resource type object representing Azure resources
- [resourceTypeFactory](wara-module-classes.md#resourcetypefactory) - Factory for creating resource type objects
- [aprlResourceObj](wara-module-classes.md#aprlresourceobj) - Resource object representing individual Azure resources
- [impactedResourceFactory](wara-module-classes.md#impactedresourcefactory) - Factory for creating impacted resource objects
- [validationResourceFactory](wara-module-classes.md#validationresourcefactory) - Factory for creating validation resource objects
- [specializedResourceFactory](wara-module-classes.md#specializedresourcefactory) - Factory for creating specialized resource objects
