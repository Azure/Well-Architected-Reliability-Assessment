using module ../utils/utils.psd1

<#
.FUNCTION
    Get-RunbookSchema

.SYNOPSIS
    Retrieves the JSON schema for a runbook.

.DESCRIPTION
    The `Get-RunbookSchema` function returns the JSON schema that defines the structure
    of a Well-Architected Reliability Assessment (WARA) runbook. This schema ensures consistency
    in the configuration and validation of runbook content.

.OUTPUTS
    [string]
    The JSON schema as a string.

.EXAMPLE
    $schema = Get-RunbookSchema

    Retrieves the JSON schema for a runbook, ensuring it adheres to the expected structure.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function Get-RunbookSchema {
    @"
{
  "title": "Runbook",
  "description": "A well-architected reliability assessment (WARA) runbook",
  "type": "object",
  "properties": {
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
.FUNCTION
    New-RunbookFactory

.SYNOPSIS
    Instantiates a new RunbookFactory object.

.DESCRIPTION
    The `New-RunbookFactory` function creates an instance of the `RunbookFactory` class,
    which is responsible for parsing runbook files and generating `Runbook` instances.

.OUTPUTS
    [RunbookFactory]
    A new instance of the RunbookFactory class.

.EXAMPLE
    $factory = New-RunbookFactory

    Creates a new instance of the RunbookFactory class, which can then be used
    to parse runbook content.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookFactory {
    return [RunbookFactory]::new()
}

<#
.FUNCTION
    New-Runbook

.SYNOPSIS
    Creates a new Runbook instance.

.DESCRIPTION
    The `New-Runbook` function returns a new instance of the `Runbook` class.
    It can optionally be initialized from a JSON string (-FromJson) or a JSON file (-FromJsonFile),
    but not both.

.PARAMETER FromJson
    JSON content to initialize the runbook. Cannot be used with -FromJsonFile.

.PARAMETER FromJsonFile
    Path to a JSON file to initialize the runbook. Cannot be used with -FromJson.

.OUTPUTS
    [Runbook]
    A new `Runbook` instance.

.EXAMPLE
    $runbook = New-Runbook

    Creates an empty `Runbook` instance.

.EXAMPLE
    $runbook = New-Runbook -FromJson $jsonContent

    Initializes a `Runbook` instance from JSON content.

.EXAMPLE
    $runbook = New-Runbook -FromJsonFile "C:\runbook.json"

    Initializes a `Runbook` instance from a JSON file.

.NOTES
    - If neither `-FromJson` nor `-FromJsonFile` is specified, an empty `Runbook` instance is returned.
    - If both `-FromJson` and `-FromJsonFile` are specified, the function throws an error.
    - The provided JSON must be valid and match the expected `Runbook` schema.

    Author: Casey Watson
    Date: 2025-02-27
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
.FUNCTION
    New-Recommendation

.SYNOPSIS
    Creates a new `Recommendation` instance.

.DESCRIPTION
    The `New-Recommendation` function initializes and returns a new instance of the `Recommendation` class.
    This object contains metadata and evaluation logic for a specific runbook check.

.OUTPUTS
    [Recommendation]
    A new `Recommendation` object.

.EXAMPLE
    $recommendation = New-Recommendation

    Creates a new `Recommendation` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-Recommendation {
    return [Recommendation]::new()
}

<#
.FUNCTION
    New-RunbookRecommendation

.SYNOPSIS
    Creates a new `RunbookRecommendation` instance.

.DESCRIPTION
    The `New-RunbookRecommendation` function initializes and returns a new instance of
    the `RunbookRecommendation` class, which encapsulates metadata for a specific runbook
    check, including its associated recommendation.

.OUTPUTS
    [RunbookRecommendation]
    A new `RunbookRecommendation` object.

.EXAMPLE
    $runbookRecommendation = New-RunbookRecommendation

    Creates a new `RunbookRecommendation` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookRecommendation {
    return [RunbookRecommendation]::new()
}

<#
.FUNCTION
    New-RunbookCheckSet

.SYNOPSIS
    Creates a new `RunbookCheckSet` instance.

.DESCRIPTION
    The `New-RunbookCheckSet` function returns a new instance of the `RunbookCheckSet` class,
    which represents a logical grouping of related runbook checks.

.OUTPUTS
    [RunbookCheckSet]
    A new `RunbookCheckSet` instance.

.EXAMPLE
    $checkSet = New-RunbookCheckSet

    Creates a new `RunbookCheckSet` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookCheckSet {
    return [RunbookCheckSet]::new()
}

<#
.FUNCTION
    New-RunbookCheck

.SYNOPSIS
    Creates a new `RunbookCheck` instance.

.DESCRIPTION
    The `New-RunbookCheck` function returns a new instance of the `RunbookCheck` class,
    representing an individual check within a runbook. Each check is associated with a selector
    and contains parameterized logic for evaluating resource compliance.

.OUTPUTS
    [RunbookCheck]
    A new `RunbookCheck` instance.

.EXAMPLE
    $check = New-RunbookCheck

    Creates a new `RunbookCheck` instance.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function New-RunbookCheck {
    return [RunbookCheck]::new()
}

<#
.FUNCTION
    Build-RunbookQueries

.SYNOPSIS
    Constructs queries for runbook checks.

.DESCRIPTION
    The `Build-RunbookQueries` function generates a list of queries based on the check sets
    and associated recommendations within a runbook. It dynamically merges parameters, variables,
    and selectors to construct accurate queries for evaluation.

.PARAMETER Runbook
    The `Runbook` object containing check sets, parameters, and selectors.

.PARAMETER Recommendations
    An array of `RunbookRecommendation` objects defining the checks to be executed.

.PARAMETER ProgressId
    (Optional) A progress indicator ID for `Write-Progress`.

.OUTPUTS
    [RunbookQuery[]]
    An array of `RunbookQuery` objects, each containing a check name, query, tags, and recommendation.

.EXAMPLE
    $queries = Build-RunbookQueries -Runbook $runbook -Recommendations $recommendations

    Constructs queries for the given runbook and recommendations.

.NOTES
    - Queries are created by combining parameters, variables, and selectors with recommendation queries.
    - Throws an error if a check references a missing selector.
    - Ensures that only recommendations matching the runbook's check sets are processed.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Build-RunbookQueries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Runbook] $Runbook,

        [Parameter(Mandatory = $true)]
        [RunbookRecommendation[]] $Recommendations,

        [Parameter(Mandatory = $false)]
        [int] $ProgressId = 30
    )

    $checkCount = 0
    $checkIndex = 0

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        $checkSet = $Runbook.CheckSets[$checkSetKey]
        $checkCount += $checkSet.Checks.Count
    }

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

    $recommendationsMap = @{}

    foreach ($recommendation in $Recommendations) {
        if (-not ($recommendationsMap.ContainsKey($recommendation.CheckSetName))) {
            $recommendationsMap[$recommendation.CheckSetName] = @{}
        }

        $recommendationsMap[$recommendation.CheckSetName][$recommendation.CheckName] = $recommendation.Recommendation
    }

    foreach ($checkSetKey in $Runbook.CheckSets.Keys) {
        if (-not ($recommendationsMap.ContainsKey($checkSetKey))) {
            throw "No recommendations found for check set [$checkSetKey]."
        }

        $checkSet = $Runbook.CheckSets[$checkSetKey]

        foreach ($checkKey in $checkSet.Checks.Keys) {
            $checkIndex++
            $pctComplete = (($checkIndex / $checkCount) * 100)

            Write-Progress `
                -Activity "Building runbook queries" `
                -Status "$checkKey" `
                -PercentComplete $pctComplete `
                -Id $ProgressId

            if (-not ($recommendationsMap[$checkSetKey].ContainsKey($checkKey))) {
                throw "No recommendation found for check [$checkSetKey]:[$checkKey]."
            }

            $check = $checkSet.Checks[$checkKey]
            $recommendation = $recommendationsMap[$checkSetKey][$checkKey]

            $checkParameters = @{}
            $checkParameters += $globalParameters

            foreach ($checkParameterKey in $check.Parameters.Keys) {
                $checkParameterValue = $check.Parameters[$checkParameterKey].ToString()
                $checkParameters[$checkParameterKey] = Merge-ParametersIntoString -Parameters $globalParameters -Into $checkParameterValue
            }

            if ($Runbook.Selectors.ContainsKey($check.SelectorName)) {
                $query = Merge-ParametersIntoString -Parameters $checkParameters -Into $recommendation.Query

                foreach ($selectorKey in $Runbook.Selectors.Keys) {
                    $selector = $Runbook.Selectors[$selectorKey]
                    $selector = Merge-ParametersIntoString -Parameters $checkParameters -Into $selector
                    $query = $($query -replace "//\s*selector:$($selectorKey)", "| where $selector")
                }

                $selector = Merge-ParametersIntoString -Parameters $checkParameters -Into $Runbook.Selectors[$check.SelectorName]
                $query = $($query -replace "//\s*selector", "| where $selector")

                $queries += [RunbookQuery]@{
                    CheckSetName   = $checkSetKey
                    CheckName      = $checkKey
                    SelectorName   = $check.SelectorName
                    Query          = $query
                    Tags           = $check.Tags
                    Recommendation = $recommendation
                }
            }
        }
    }

    Write-Progress -Id $ProgressId -Completed

    return $queries
}

<#
.FUNCTION
    Merge-ParametersIntoString

.SYNOPSIS
    Replaces placeholders in a string with parameter values.

.DESCRIPTION
    The `Merge-ParametersIntoString` function iterates through a hashtable of parameters
    and replaces placeholders in the input string with corresponding values.
    Placeholders must follow the `{{Key}}` format.

.PARAMETER Parameters
    A hashtable containing key-value pairs for replacement.

.PARAMETER Into
    The string containing placeholders to be replaced.

.OUTPUTS
    [string]
    A string with placeholders replaced by their corresponding values.

.EXAMPLE
    $params = @{ "Region" = "eastus"; "Env" = "Production" }
    $result = Merge-ParametersIntoString -Parameters $params -Into "Deploying to {{Region}} in {{Env}}."

    Returns: "Deploying to eastus in Production."

.NOTES
    - Only placeholders matching keys in the hashtable are replaced.
    - Uses simple string replacement logic.

    Author: Casey Watson
    Date: 2025-02-27
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
.FUNCTION
    Read-RunbookFile

.SYNOPSIS
    Reads and parses a runbook file.

.DESCRIPTION
    The `Read-RunbookFile` function validates and loads a runbook from a JSON file.
    If the file is valid, it returns a parsed `Runbook` instance.

.PARAMETER Path
    The file path to the runbook JSON file.

.OUTPUTS
    [Runbook]
    A parsed `Runbook` object.

.EXAMPLE
    $runbook = Read-RunbookFile -Path "C:\runbook.json"

    Reads and parses the specified runbook file.

.NOTES
    - Uses `Test-RunbookFile` to validate the file before parsing.
    - If validation fails, an error is thrown.
    - The runbook is parsed using `RunbookFactory`.

    Author: Casey Watson
    Date: 2025-02-27
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
.FUNCTION
    Write-RunbookFile

.SYNOPSIS
    Saves a `Runbook` object to a JSON file.

.DESCRIPTION
    The `Write-RunbookFile` function validates the provided `Runbook` object
    and serializes it into a JSON file at the specified path.

.PARAMETER Runbook
    The `Runbook` object to be saved.

.PARAMETER Path
    The file path where the `Runbook` JSON should be written.

.OUTPUTS
    None

.EXAMPLE
    Write-RunbookFile -Runbook $myRunbook -Path "C:\runbook.json"

    Saves the provided `Runbook` object to "C:\runbook.json".

.NOTES
    - Ensures the `Runbook` is valid before saving.
    - The output file is formatted in JSON.

    Author: Casey Watson
    Date: 2025-02-27
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
.FUNCTION
    Test-RunbookFile

.SYNOPSIS
    Validates a runbook file.

.DESCRIPTION
    The `Test-RunbookFile` function checks whether a specified runbook JSON file is
    valid according to the runbook schema. It ensures the JSON structure is correct
    and adheres to expected schema requirements.

.PARAMETER Path
    The full file path to the runbook JSON file.

.OUTPUTS
    [bool]
    Returns `$true` if the file is valid; otherwise, an error is thrown.

.EXAMPLE
    $isValid = Test-RunbookFile -Path "C:\runbook.json"

    Returns `$true` if the runbook is valid.

.NOTES
    - Uses `Test-Json` to validate JSON structure.
    - If validation fails, an error is thrown.

    Author: Casey Watson
    Date: 2025-02-27
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
.FUNCTION
    Build-RunbookSelectorReview

.SYNOPSIS
    Builds a selector review for a runbook.

.DESCRIPTION
    The `Build-RunbookSelectorReview` function evaluates each selector in a runbook,
    resolves parameters, and executes queries to identify matching resources across
    specified subscriptions.

.PARAMETER Runbook
    The `Runbook` object containing selectors, parameters, and variables.

.PARAMETER SubscriptionIds
    (Optional) An array of subscription IDs to scope the queries.

.OUTPUTS
    [SelectorReview]
    A `SelectorReview` object mapping each selector to its resolved query and matched resources.

.EXAMPLE
    $review = Build-RunbookSelectorReview -Runbook $runbook -SubscriptionIds @("sub1", "sub2")

    Generates a selector review to verify correct resource scoping.

.NOTES
    - Selectors define which resources are included in a runbook.
    - Misconfigured selectors may cause missing or incorrect results.
    - Uses `Invoke-WAFQuery` to fetch matching resources.

    Author: Casey Watson
    Date: 2025-02-27
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
.FUNCTION
    Build-SelectorResourceGraphQuery

.SYNOPSIS
    Constructs an Azure Resource Graph query from a selector.

.DESCRIPTION
    The `Build-SelectorResourceGraphQuery` function creates a Resource Graph query
    that filters resources based on the provided selector expression.

.PARAMETER Selector
    The filter expression used to scope resources in the query.

.OUTPUTS
    [string]
    The formatted Azure Resource Graph query.

.EXAMPLE
    $query = Build-SelectorResourceGraphQuery -Selector "type == 'Microsoft.Compute/virtualMachines'"

    Generates a query to filter virtual machines.

.NOTES
    - The selector should be a valid KQL (Kusto Query Language) expression.
    - The output query can be executed using Azure Resource Graph API.

    Author: Casey Watson
    Date: 2025-02-27
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

