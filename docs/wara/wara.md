
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

