using module ../utils/utils.psd1

# Load classes
. "$PSScriptRoot/runbook.classes.ps1"

<#
.SYNOPSIS
    Returns the JSON schema for a runbook.

.DESCRIPTION
    Provides the JSON schema that defines the structure of a Well-Architected Reliability
    Assessment (WARA) runbook, including parameters, variables, selectors, and checks.

.OUTPUTS
    The JSON schema as a string.

.EXAMPLE
    $schema = Get-RunbookSchema

    Retrieves the JSON schema for a runbook.
#>
function Get-RunbookSchema {
    @"
{
  "title": "Runbook",
  "description": "A well-architected reliability assessment (WARA) runbook",
  "type": "object",
  "properties": {
    "query_paths": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "query_overrides": {
     "type": "array",
      "items": {
        "type": "string"
      }
    },
    "parameters": {
      "type": "object"
    },
    "variables": {
      "type": "object"
    },
    "selectors": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    },
    "checks": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "additionalProperties": {
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "selector": {
                  "type": "string"
                },
                "parameters": {
                  "type": "object"
                },
                "tags": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              },
              "required": [
                "selector"
              ]
            }
          ]
        }
      }
    }
  },
  "required": [
    "selectors",
    "checks"
  ]
}
"@
}

<#
.SYNOPSIS
    Creates a RecommendationFactory instance.

.DESCRIPTION
    Returns a new instance of the RecommendationFactory class.

.OUTPUTS
    [RecommendationFactory]

.EXAMPLE
    $factory = New-RecommendationFactory
#>
function New-RecommendationFactory {
    return [RecommendationFactory]::new()
}

<#
.SYNOPSIS
    Creates a RunbookFactory instance.

.DESCRIPTION
    Returns a new instance of the RunbookFactory class.

.OUTPUTS
    [RunbookFactory]

.EXAMPLE
    $factory = New-RunbookFactory
#>
function New-RunbookFactory {
    return [RunbookFactory]::new()
}

<#
.SYNOPSIS
    Creates a Runbook instance.

.DESCRIPTION
    Returns a new Runbook instance. Optionally, it can be initialized from a JSON string (-FromJson)
    or a JSON file (-FromJsonFile), but not both.

.PARAMETER FromJson
    JSON content to initialize the runbook. Cannot be used with -FromJsonFile.

.PARAMETER FromJsonFile
    Path to a JSON file to initialize the runbook. Cannot be used with -FromJson.

.OUTPUTS
    [Runbook]

.EXAMPLE
    $runbook = New-Runbook

    Creates an empty Runbook instance.

.EXAMPLE
    $runbook = New-Runbook -FromJson $jsonContent

    Creates a Runbook instance from JSON content.

.EXAMPLE
    $runbook = New-Runbook -FromJsonFile "C:\runbook.json"

    Creates a Runbook instance from a JSON file.

.NOTES
    - If neither -FromJson nor -FromJsonFile is specified, an empty Runbook instance is returned.
    - If both -FromJson and -FromJsonFile are specified, the function throws an error.
    - The provided JSON must be valid and match the expected Runbook schema.
#>
function New-Runbook {
    param(
        [Parameter(Mandatory = $false)]
        [string] $FromJson,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-FileExists -Path $_ })]
        [string] $FromJsonFile
    )

    if ($FromJson -or $FromJsonFile) {
        if ($FromJson -and $FromJsonFile) {
            throw "Cannot specify both -FromJson and -FromJsonFile."
        }
        else {
            $runbookFactory = New-RunbookFactory

            if ($FromJson) {
                return $runbookFactory.ParseRunbookContent($FromJson)
            }
            elseif ($(Test-RunbookFile -Path $FromJsonFile)) {
                return $runbookFactory.ParseRunbookFile($FromJsonFile)
            }
        }
    }
    else {
        return [Runbook]::new()
    }
}

<#
.SYNOPSIS
    Creates a RunbookCheckSet instance.

.DESCRIPTION
    Returns a new instance of the RunbookCheckSet class, which represents a set of checks
    within a runbook.

.OUTPUTS
    [RunbookCheckSet]

.EXAMPLE
    $checkSet = New-RunbookCheckSet

    Creates a new RunbookCheckSet instance.

.NOTES
    A RunbookCheckSet groups related checks within a runbook for evaluation.
#>
function New-RunbookCheckSet {
    return [RunbookCheckSet]::new()
}

<#
.SYNOPSIS
    Creates a RunbookCheck instance.

.DESCRIPTION
    Returns a new instance of the RunbookCheck class, representing an individual check within a runbook.

.OUTPUTS
    [RunbookCheck]

.EXAMPLE
    $check = New-RunbookCheck

    Creates a new RunbookCheck instance.

.NOTES
    A RunbookCheck represents a single validation or compliance check within a runbook.
#>
function New-RunbookCheck {
    return [RunbookCheck]::new()
}

<#
.SYNOPSIS
    Executes queries for runbook checks.

.DESCRIPTION
    Runs queries for each applicable recommendation in the runbook and retrieves resources
    from the specified subscriptions. Tracks progress and logs errors if queries fail.

.PARAMETER Runbook
    The runbook containing check sets and associated parameters.

.PARAMETER Recommendations
    An array of recommendations, each corresponding to a check set in the runbook.

.PARAMETER SubscriptionIds
    An array of subscription IDs to scope the queries.

.PARAMETER ProgressId
    (Optional) The ID used for tracking progress with Write-Progress. Default is 1.

.OUTPUTS
    An array of resources retrieved from the executed queries.

.EXAMPLE
    $resources = Invoke-RunbookQueryLoop -Runbook $runbook -Recommendations $recommendations -SubscriptionIds @("sub1", "sub2")

    Runs queries for the specified recommendations within the runbook and retrieves resources.

.NOTES
    - Only recommendations with automation enabled and a defined query will be processed.
    - Uses Write-Progress to display execution progress.
    - Queries are executed using Invoke-WAFQuery, and failures are logged as errors.
#>
function Invoke-RunbookQueryLoop {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [Recommendation[]] $Recommendations,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [int] $ProgressId = 1
    )

    $autoRecs = $Recommendations | Where-Object { $_.AutomationAvailable -eq $true -and $_.Query }
    $queries = @(Build-RunbookQueries -Runbook $Runbook -Recommendations $autoRecs)

    $return = $queries | ForEach-Object {
        $checkTitle = "[$($_.CheckSetName)]:[$($_.CheckName)]"

        Write-Progress `
            -Activity "Running runbook queries" `
            -Status "Running runbook check $checkTitle" `
            -PercentComplete (($queries.IndexOf($_) / $queries.Count) * 100) `
            -Id $ProgressId

        try {
            Invoke-WAFQuery -Query $_.Query -SubscriptionIds $SubscriptionIds -ErrorAction Stop
        }
        catch {
            Write-Error "Error running query for runbook check [$($_.CheckSetName):$($_.CheckName)]"
        }
    }

    Write-Progress -Activity 'Running runbook queries' -Status 'Completed!' -Completed -Id $ProgressId

    return @($return)
}

<#
.SYNOPSIS
    Builds queries for runbook checks.

.DESCRIPTION
    Generates a list of queries based on the runbook's check sets and corresponding recommendations.
    This function resolves parameters, variables, and selectors to construct queries dynamically.

.PARAMETER Runbook
    The runbook containing check sets, parameters, and selectors.

.PARAMETER Recommendations
    An array of recommendations that define the checks to be executed.

.OUTPUTS
    [RunbookQuery[]]
    Returns an array of RunbookQuery objects, each containing a check name, query, tags, and recommendation.

.EXAMPLE
    $queries = Build-RunbookQueries -Runbook $runbook -Recommendations $recommendations

    Builds queries for the specified runbook and recommendations.

.NOTES
    - Queries are generated by merging parameters, variables, and selectors into the recommendation queries.
    - Throws an error if a check references a missing selector.
    - Ensures that only recommendations matching the runbook's check sets are processed.
#>
function Build-RunbookQueries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [Recommendation[]] $Recommendations
    )

    $queries = @()
    $globalParameters = @{}

    if ($Runbook.Parameters) {
        foreach ($globalParameterKey in $Runbook.Parameters.Keys) {
            $globalParameters[$globalParameterKey] = $Runbook.Parameters[$globalParameterKey].ToString()
        }
    }

    if ($Runbook.Variables) {
        foreach ($variableKey in $Runbook.Variables.Keys) {
            $variableValue = $Runbook.Variables[$variableKey].ToString()
            $globalParameters[$variableKey] = Merge-ParametersIntoString -Parameters $globalParameters -Into $variableValue
        }
    }

    $recommendationsHash = @{}
    $Recommendations.ForEach({ $recommendationsHash[$_.AprlGuid] = $_ })

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        if ($recommendationsHash.ContainsKey($checkSetKey)) {
            $checkSet = $Runbook.CheckSets[$checkSetKey]
            $recommendation = $recommendationsHash[$checkSetKey]

            foreach ($checkKey in $checkSet.Checks.Keys) {
                $check = $checkSet.Checks[$checkKey]

                $checkParameters = @{}
                $checkParameters += $globalParameters

                foreach ($checkParameterKey in $check.Parameters.Keys) {
                    $checkParameterValue = $check.Parameters[$checkParameterKey].ToString()
                    $checkParameters[$checkParameterKey] = Merge-ParametersIntoString -Parameters $checkParameters -Into $checkParameterValue
                }

                if ($Runbook.Selectors.ContainsKey($check.SelectorName)) {
                    $query = Merge-ParametersIntoString -Parameters $checkParameters -Into $recommendation.Query

                    foreach ($selectorKey in $Runbook.Selectors.Keys) {
                        $namedSelector = Merge-ParametersIntoString -Parameters $checkParameters -Into $Runbook.Selectors[$selectorKey]
                        $query = $($query -replace "\\\\\s*selector:$selectorKey", "| where $namedSelector")
                    }

                    $selector = Merge-ParametersIntoString -Parameters $checkParameters -Into $Runbook.Selectors[$check.SelectorName]
                    $query = $($query -replace "\\\\\s*selector", "| where $selector")

                    $queries += [RunbookQuery]@{
                        CheckSetName   = $checkSetKey
                        CheckName      = $checkKey
                        Query          = $query
                        Tags           = $check.Tags
                        Recommendation = $recommendation
                    }
                }
                else {
                    throw "Runbook check [$checkSetKey]:[$checkKey] references a selector that does not exist: [$($check.SelectorName)]."
                }
            }
        }
        else {
            throw "Runbook check set [$checkSetKey] recommendation not found."
        }
    }

    return $queries
}

<#
.SYNOPSIS
    Replaces placeholders in a string with parameter values.

.DESCRIPTION
    Iterates through a hashtable of parameters and replaces placeholders in the input string
    with corresponding values. Placeholders are expected in the format `{{Key}}`.

.PARAMETER Parameters
    A hashtable containing key-value pairs to replace in the string.

.PARAMETER Into
    The string containing placeholders to be replaced.

.OUTPUTS
    [string]
    Returns the updated string with placeholders replaced.

.EXAMPLE
    $params = @{ "Region" = "eastus"; "Env" = "Production" }
    $result = Merge-ParametersIntoString -Parameters $params -Into "Deploying to {{Region}} in {{Env}}."

    Output: "Deploying to eastus in Production."

.NOTES
    - Placeholders must be wrapped in double curly braces (e.g., `{{Key}}`).
    - Only placeholders matching keys in the hashtable are replaced.
#>
function Merge-ParametersIntoString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable] $Parameters,

        [Parameter(Mandatory = $true)]
        [string] $Into
    )

    foreach ($parameterKey in $Parameters.Keys) {
        $Into = $Into.Replace("{{$parameterKey}}", $Parameters[$parameterKey])
    }

    return $Into
}

<#
.SYNOPSIS
    Reads and parses a runbook file.

.DESCRIPTION
    Validates the existence of the specified runbook file and, if valid, parses it.

.PARAMETER Path
    The file path to the runbook JSON file.

.OUTPUTS
    Returns a parsed Runbook object if the file is valid.

.EXAMPLE
    $runbook = Read-RunbookFile -Path "C:\path\to\runbook.json"

    Reads and parses the specified runbook file.

.NOTES
    - Uses Test-RunbookFile to validate the file before parsing.
    - If the file is invalid, the function throws an error.
#>
function Read-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    if (Test-RunbookFile -Path $Path) {
        $runbookFactory = New-RunbookFactory
        return $runbookFactory.ParseRunbookFile($Path)
    }
}

<#
.SYNOPSIS
    Saves a Runbook object to a JSON file.

.DESCRIPTION
    Validates the given Runbook object and serializes it to a JSON file
    at the specified path.

.PARAMETER Runbook
    The Runbook object to be saved.

.PARAMETER Path
    The file path where the Runbook JSON should be written.

.EXAMPLE
    Write-RunbookFile -Runbook $myRunbook -Path "C:\runbook.json"

    Saves the provided Runbook object to "C:\runbook.json".

.NOTES
    - Ensures the Runbook is valid before saving.
#>
function Write-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $Runbook.Validate()

    $runbookFileContents = @{
        query_paths = $Runbook.QueryPaths
        parameters  = $Runbook.Parameters
        variables   = $Runbook.Variables
        selectors   = $Runbook.Selectors
        checks      = @{}
    }

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        $checkSet = $Runbook.CheckSets[$checkSetKey]
        $checkSetContents = @{}

        foreach ($checkKey in $checkSet.Checks.Keys) {
            $check = $checkSet.Checks[$checkKey]

            $checkContents = @{
                parameters = ($check.Parameters ?? @{})
                selector   = $check.SelectorName
                tags       = ($check.Tags ?? @())
            }

            $checkSetContents[$checkKey] = $checkContents
        }

        $runbookFileContents.checks[$checkSetKey] = $checkSetContents
    }

    $runbookFileJson = $runbookFileContents | ConvertTo-Json -Depth 15
    $runbookFileJson | Out-File -FilePath $Path -Force
}

<#
.SYNOPSIS
    Reads and parses a runbook JSON file.

.DESCRIPTION
    Validates and loads a runbook from a JSON file, returning a Runbook instance if the file is valid.

.PARAMETER Path
    The full path to the runbook JSON file.

.OUTPUTS
    [Runbook]
    Returns a parsed Runbook instance if the file is valid.

.EXAMPLE
    $runbook = Read-RunbookFile -Path "C:\runbook.json"

    Reads and parses the specified runbook file.

.NOTES
    - The function first validates the file using Test-RunbookFile.
    - If validation fails, an error is thrown.
    - The returned Runbook instance is parsed using RunbookFactory.
#>
function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    $fileContent = Get-Content -Path $Path -Raw

    if (-not ($fileContent | Test-Json -ErrorAction SilentlyContinue)) {
        throw "[$Path] is not a valid JSON file."
    }

    if (-not ($fileContent | Test-Json -ErrorAction SilentlyContinue -Schema $(Get-RunbookSchema))) {
        throw "[$Path] does not adhere to the runbook JSON schema. Run [Get-RunbookSchema] to get the schema."
    }

    $runbookFactory = New-RunbookFactory
    $runbookFactory.ParseRunbookContent($fileContent).Validate()

    return $true
}

<#
.SYNOPSIS
    Builds a selector review for a runbook.

.DESCRIPTION
    Evaluates each selector in the runbook, resolves parameters, and executes queries
    to identify matching resources across specified subscriptions.

    Selector reviews help users verify that their selectors are correctly configured
    and ensure the correct resources are in scope.

.PARAMETER Runbook
    The runbook containing selectors, parameters, and variables.

.PARAMETER SubscriptionIds
    (Optional) An array of subscription IDs to scope the queries. Defaults to an empty collection.

.OUTPUTS
    [SelectorReview]
    Returns a SelectorReview object mapping each selector to its resolved query and matching resources.

.EXAMPLE
    $review = Build-RunbookSelectorReview -Runbook $runbook -SubscriptionIds @("sub1", "sub2")

    Generates a selector review to verify correct resource scoping within the specified subscriptions.

.NOTES
    - Selectors define which resources are included in a runbook, making them critical to accuracy.
    - Misconfigured selectors can lead to missing or incorrect results.
    - This function helps validate selector logic by merging parameters and variables, running queries,
      and displaying a progress status.
    - Uses Write-Progress to track execution.
    - Queries are executed using Invoke-WAFQuery to fetch matching resources.
#>
function Build-RunbookSelectorReview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]] $SubscriptionIds
    )

    $selectorReview = [SelectorReview]::new()

    $globalParameters = @{}

    if ($Runbook.Parameters) {
        foreach ($globalParameterKey in $Runbook.Parameters.Keys) {
            $globalParameters[$globalParameterKey] = $Runbook.Parameters[$globalParameterKey].ToString()
        }
    }

    if ($Runbook.Variables) {
        foreach ($variableKey in $Runbook.Variables.Keys) {
            $variableValue = $Runbook.Variables[$variableKey].ToString()
            $globalParameters[$variableKey] = Merge-ParametersIntoString -Parameters $globalParameters -Into $variableValue
        }
    }

    for ($i = 0; $i -lt $Runbook.Selectors.Keys.Count; $i++) {
        $selectorKey = $Runbook.Selectors.Keys[$i]
        $selector = Merge-ParametersIntoString -Parameters $globalParameters -Into $Runbook.Selectors[$selectorKey]
        $pctComplete = ((($i + 1) / $Runbook.Selectors.Keys.Count) * 100)

        Write-Progress `
            -Activity "Building selector review..." `
            -Status "$pctComplete% - Processing selector [$selectorKey]" `
            -PercentComplete $pctComplete

        $selectedResourceSet = [SelectedResourceSet]@{
            Selector           = $selector
            ResourceGraphQuery = Build-SelectorResourceGraphQuery -Selector $selector
        }

        $selectedResources = Invoke-WAFQuery `
            -Query $selectedResourceSet.SelectorResourceGraphQuery `
            -SubscriptionIds $SubscriptionIds

        foreach ($selectedResource in $selectedResources) {
            $selectedResourceSet.Resources += [SelectedResource]@{
                ResourceId        = $selectedResource.id
                ResourceType      = $selectedResource.type
                ResourceName      = $selectedResource.name
                ResourceLocation  = $selectedResource.location
                ResourceGroupName = $selectedResource.resourceGroup
                ResourceTags      = $(ConvertTo-Json $selectedResource.tags | ConvertFrom-Json -AsHashtable)
            }
        }

        $selectorReview.Selectors[$selectorKey] = $selectedResourceSet
    }

    Write-Progress -Activity "Selector review built." -Completed

    return $selectorReview
}

<#
.SYNOPSIS
    Generates a Resource Graph query based on a selector.

.DESCRIPTION
    Constructs an Azure Resource Graph query that filters resources based on the provided selector.
    The query selects key attributes such as resource ID, type, location, name, resource group, and tags.

.PARAMETER Selector
    The filter expression used to scope resources in the Azure Resource Graph query.

.OUTPUTS
    [string]
    Returns the formatted Azure Resource Graph query.

.EXAMPLE
    $query = Build-SelectorResourceGraphQuery -Selector "type == 'Microsoft.Compute/virtualMachines'"

    Generates a query to filter virtual machines.

.NOTES
    - The selector should be a valid KQL (Kusto Query Language) filter.
    - The returned query can be executed using Azure Resource Graph API or related tools.
#>
function Build-SelectorResourceGraphQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Selector
    )

    return @"
resources
| where $Selector
| project id, type, location, name, resourceGroup, tags
"@
}

