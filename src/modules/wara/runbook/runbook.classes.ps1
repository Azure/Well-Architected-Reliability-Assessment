<#
.CLASS
    Recommendation

.SYNOPSIS
    Represents a recommendation associated with a runbook check.

.DESCRIPTION
    The `Recommendation` class defines a recommendation, including metadata,
    impact assessment, query logic, and automation availability.
    This class is used within the runbook module to define checks
    and their associated guidance.

.PROPERTY AprlGuid
    A unique identifier for the recommendation, if applicable.

.PROPERTY CheckName
    The name of the check associated with this recommendation.

.PROPERTY RecommendationTypeId
    The type identifier for this recommendation.

.PROPERTY RecommendationMetadataState
    The current state of the recommendation (e.g., Active, Deprecated).

.PROPERTY RecommendationControl
    The control category associated with the recommendation.

.PROPERTY LongDescription
    A detailed explanation of the recommendation, its purpose, and implementation guidance.

.PROPERTY Description
    A brief summary of the recommendation.

.PROPERTY PotentialBenefits
    A concise statement highlighting the benefits of implementing the recommendation.

.PROPERTY RecommendationResourceType
    The resource type that the recommendation applies to.

.PROPERTY RecommendationImpact
    The expected impact of following or ignoring the recommendation.

.PROPERTY Query
    The query logic used to evaluate compliance with the recommendation.

.PROPERTY Links
    A hashtable containing additional reference links for further details.

.PROPERTY Tags
    An array of tags categorizing or classifying the recommendation.

.PROPERTY PgVerified
    Indicates whether the recommendation has been verified by the product group.

.PROPERTY AutomationAvailable
    Indicates whether automation is available to apply the recommendation.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class Recommendation {
    [string] $AprlGuid
    [string] $CheckName
    [string] $RecommendationTypeId
    [string] $RecommendationMetadataState
    [string] $RecommendationControl
    [string] $LongDescription
    [string] $Description
    [string] $PotentialBenefits
    [string] $RecommendationResourceType
    [string] $RecommendationImpact
    [string] $Query

    [hashtable] $Links = @{}

    [string[]] $Tags = @()

    [bool] $PgVerified
    [bool] $AutomationAvailable
}

<#
.CLASS
    RunbookRecommendation

.SYNOPSIS
    Represents a recommendation within a runbook.

.DESCRIPTION
    The `RunbookRecommendation` class encapsulates a specific recommendation
    as part of a runbook. It includes metadata such as the check set name,
    the individual check name, and an associated `Recommendation` object.

.PROPERTY CheckSetName
    The name of the check set that this recommendation belongs to.

.PROPERTY CheckName
    The name of the specific check within the check set.

.PROPERTY Recommendation
    The `Recommendation` object associated with this runbook entry.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class RunbookRecommendation {
    [string] $CheckSetName
    [string] $CheckName

    [Recommendation] $Recommendation
}

<#
.CLASS
    RunbookQuery

.SYNOPSIS
    Represents a query associated with a runbook check.

.DESCRIPTION
    The `RunbookQuery` class stores query details for a specific check within
    a runbook check set. It includes metadata such as the check set and check name,
    the query string, selector name, associated tags, and the linked recommendation.

.PROPERTY CheckSetName
    The name of the check set containing this query.

.PROPERTY CheckName
    The name of the specific check associated with the query.

.PROPERTY SelectorName
    The selector used for filtering resources in the query.

.PROPERTY Query
    The query string to evaluate the check.

.PROPERTY Tags
    An array of tags associated with this query.

.PROPERTY Recommendation
    The `Recommendation` object related to this query.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>

class RunbookQuery {
    [string] $CheckSetName
    [string] $CheckName
    [string] $SelectorName
    [string] $Query

    [string[]] $Tags

    [Recommendation] $Recommendation
}

<#
.CLASS
    RunbookCheck

.SYNOPSIS
    Represents a check within a runbook.

.DESCRIPTION
    The `RunbookCheck` class defines an individual check, including its selector,
    parameters, and associated tags. It is part of a `RunbookCheckSet` and is used
    to evaluate specific conditions within a runbook.

.PROPERTY SelectorName
    The name of the selector applied to this check.

.PROPERTY Parameters
    A hashtable of parameters specific to this check.

.PROPERTY Tags
    An array of tags categorizing this check.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class RunbookCheck {
    [string] $SelectorName

    [hashtable] $Parameters = @{}

    [string[]] $Tags = @()
}

<#
.CLASS
    RunbookCheckSet

.SYNOPSIS
    Represents a set of runbook checks.

.DESCRIPTION
    The `RunbookCheckSet` class groups multiple `RunbookCheck` objects, allowing them
    to be organized and evaluated together as part of a runbook.

.PROPERTY Checks
    A hashtable containing `RunbookCheck` objects.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class RunbookCheckSet {
    [hashtable] $Checks = @{}
}

<#
.CLASS
    Runbook

.SYNOPSIS
    Represents a runbook containing check sets, selectors, and parameters.

.DESCRIPTION
    The `Runbook` class defines the structure of a runbook, including parameters,
    variables, selectors, and check sets. It provides a `Validate` method to
    ensure the runbook is correctly configured before execution.

.PROPERTY Parameters
    A hashtable of parameters defined within the runbook.

.PROPERTY Variables
    A hashtable of variables used in the runbook.

.PROPERTY Selectors
    A hashtable of selectors that define resource filters.

.PROPERTY CheckSets
    A hashtable of `RunbookCheckSet` objects.

.METHOD Validate
    Ensures the runbook is properly configured by verifying that all required elements exist.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class Runbook {
    [hashtable] $Parameters = @{}
    [hashtable] $Variables = @{}
    [hashtable] $Selectors = @{}
    [hashtable] $CheckSets = @{}

    [void] Validate() {
        $errors = @()

        if ($this.Selectors.Count -eq 0) {
            $errors += "- [selectors]: At least one (1) selector is required."
        }

        if ($this.CheckSets.Count -eq 0) {
            $errors += "- [checks]: At least one (1) check set is required."
        }

        foreach ($checkSetKey in $this.CheckSets.Keys) {
            $checkSet = $this.CheckSets[$checkSetKey]

            foreach ($checkKey in $checkSet.Checks.Keys) {
                $check = $checkSet.Checks[$checkKey]
                $checkTitle = "[$checkSetKey]:[$checkKey]"

                if (-not $this.Selectors.ContainsKey($check.SelectorName)) {
                    $errors += "- [checks]: $checkTitle references a selector that does not exist: [$($check.SelectorName)]."
                }
            }
        }

        if ($errors.Count -gt 0) {
            throw "Runbook is invalid:`n$($errors -join "`n")"
        }
    }
}

<#
.CLASS
    SelectorReview

.SYNOPSIS
    Stores the results of a selector review.

.DESCRIPTION
    The `SelectorReview` class contains resolved selectors and their associated
    resources after evaluation. It helps users verify that selectors are correctly
    configured and returning the expected results.

.PROPERTY Selectors
    A hashtable mapping selector names to selected resource sets.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class SelectorReview {
    [hashtable] $Selectors = @{}
}

<#
.CLASS
    SelectedResourceSet

.SYNOPSIS
    Represents a set of resources selected by a query.

.DESCRIPTION
    The `SelectedResourceSet` class stores the results of a resource selection
    based on a selector and an Azure Resource Graph query.

.PROPERTY Selector
    The selector that determined the resource set.

.PROPERTY ResourceGraphQuery
    The query used to retrieve resources.

.PROPERTY Resources
    An array of `SelectedResource` objects.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class SelectedResourceSet {
    [string] $Selector
    [string] $ResourceGraphQuery

    [SelectedResource[]] $Resources = @()
}

<#
.CLASS
    SelectedResource

.SYNOPSIS
    Represents a selected resource.

.DESCRIPTION
    The `SelectedResource` class stores details about a resource, including
    its ID, type, name, location, resource group, and tags.

.PROPERTY ResourceId
    The unique identifier of the resource.

.PROPERTY ResourceType
    The type of the resource.

.PROPERTY ResourceName
    The name of the resource.

.PROPERTY ResourceLocation
    The geographical location of the resource.

.PROPERTY ResourceGroupName
    The resource group that contains the resource.

.PROPERTY ResourceTags
    A hashtable of key-value pairs representing resource tags.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
class SelectedResource {
    [string] $ResourceId
    [string] $ResourceType
    [string] $ResourceName
    [string] $ResourceLocation
    [string] $ResourceGroupName

    [hashtable] $ResourceTags = @{}
}

<#
.CLASS
    RunbookFactory

.SYNOPSIS
    Parses and creates Runbook objects.

.DESCRIPTION
    The `RunbookFactory` class provides methods to parse runbooks from a JSON file
    or raw JSON content, returning a `Runbook` instance.

.METHOD ParseRunbookFile
    Reads and parses a runbook from a JSON file.

.METHOD ParseRunbookContent
    Parses a runbook from raw JSON content.

.NOTES
    - If the file does not exist, `ParseRunbookFile` returns `$null`.
    - Supports both simple and structured check definitions.
    - Automatically initializes missing properties as empty collections.

    Author: Casey Watson
    Date: 2025-02-27
#>
class RunbookFactory {
    [Runbook] ParseRunbookFile([string] $path) {
        if (Test-FileExists -Path $path) {
            $fileContent = Get-Content -Path $path -Raw
            return $this.ParseRunbookContent($fileContent)
        }

        return $null
    }

    [Runbook] ParseRunbookContent([string] $content) {
        $runbookHash = ($content | ConvertFrom-Json -AsHashtable)

        $runbook = [Runbook]@{
            Parameters = ($runbookHash.parameters ?? @{})
            Variables  = ($runbookHash.variables ?? @{})
            Selectors  = ($runbookHash.selectors ?? @{})
        }

        foreach ($checkSetKey in $runbookHash.checks.Keys) {
            $checkSet = [RunbookCheckSet]::new()
            $checkSetHash = $runbookHash.checks[$checkSetKey]

            foreach ($checkKey in $checkSetHash.Keys) {
                $check = [RunbookCheck]::new()
                $checkValue = $checkSetHash[$checkKey]

                switch ($checkValue.GetType().Name.ToLower()) {
                    "string" {
                        $check.SelectorName = $checkValue
                    }
                    "orderedhashtable" {
                        $check.SelectorName = $checkValue.selector
                        $check.Parameters = ($checkValue.parameters ?? @{})
                        $check.Tags = ($checkValue.tags ?? @())
                    }
                }

                $checkSet.Checks[$checkKey] = $check
            }

            $runbook.CheckSets[$checkSetKey] = $checkSet
        }

        return $runbook
    }
}
