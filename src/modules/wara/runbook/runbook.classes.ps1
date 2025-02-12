class Recommendation {
    [string] $AprlGuid
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

class RunbookQuery {
    [string] $CheckSetName
    [string] $CheckName
    [string] $Query

    [string[]] $Tags

    [Recommendation] $Recommendation
}

class RunbookCheck {
    [string] $GroupingName
    [string] $SelectorName

    [hashtable] $Parameters = @{}

    [string[]] $Tags = @()
}

class RunbookCheckSet {
    [hashtable] $Checks = @{}
}

class Runbook {
    [string[]] $QueryPaths = @()

    [hashtable] $Parameters = @{}
    [hashtable] $Variables = @{}
    [hashtable] $Selectors = @{}
    [hashtable] $Groupings = @{}
    [hashtable] $CheckSets = @{}

    static [string] $Schema = @'
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
    "groupings": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
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
                "grouping": {
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
'@

    [void] Validate() {
        $errors = @()

        if ($this.Selectors.Count -eq 0) {
            $errors += "- [selectors]: At least one (1) selector is required."
        }

        if ($this.CheckSets.Count -eq 0) {
            $errors += "- [checks]: At least one (1) check set is required."
        }

        foreach ($queryPath in $this.QueryPaths) {
            if (-not (Test-Path -PathType Container -Path $queryPath)) {
                $errors += "- [query_paths (query_overrides)]: [$queryPath] does not exist or is not a directory."
            }
        }

        foreach ($checkSetKey in $this.CheckSets.Keys) {
            $checkSet = $this.CheckSets[$checkSetKey]

            foreach ($checkKey in $checkSet.Checks.Keys) {
                $check = $checkSet.Checks[$checkKey]
                $checkTitle = "[$checkSetKey]:[$checkKey]"

                if (-not $this.Selectors.ContainsKey($check.SelectorName)) {
                    $errors += "- [checks]: $checkTitle references a selector that does not exist: [$($check.SelectorName)]."
                }

                if ($check.GroupingName -and -not $this.Groupings.ContainsKey($check.GroupingName)) {
                    $errors += "- [checks]: $checkTitle references a grouping that does not exist: [$($check.GroupingName)]."
                }
            }
        }

        if ($errors.Count -gt 0) {
            throw "Runbook is invalid:`n$($errors -join "`n")"
        }
    }
}

class SelectorReview {
    [hashtable] $Selectors = @{}
}

class SelectedResourceSet {
    [string] $Selector
    [string] $ResourceGraphQuery

    [SelectedResource[]] $Resources = @{}
}

class SelectedResource {
    [string] $ResourceId
    [string] $ResourceType
    [string] $ResourceName
    [string] $ResourceLocation
    [string] $ResourceGroupName

    [hashtable] $ResourceTags = @{}
}

class RecommendationFactory {
    [Recommendation[]] ParseRecommendationsFile([string] $path) {
        $fileContent = Get-Content -Path $path -Raw
        return $this.ParseRecommendationsContent($fileContent)
    }

    [Recommendation[]] ParseRecommendationsContent([string] $content) {
        $recommendations = @()

        foreach ($contentRecommendation in ($content | ConvertFrom-Json)) {
            $recommendation = [Recommendation]@{
                AprlGuid                    = $contentRecommendation.aprlGuid
                RecommendationTypeId        = $contentRecommendation.recommendationTypeId
                RecommendationMetadataState = $contentRecommendation.recommendationMetadataState
                RecommendationControl       = $contentRecommendation.recommendationControl
                LongDescription             = $contentRecommendation.longDescription
                PgVerified                  = $contentRecommendation.pgVerified
                Description                 = $contentRecommendation.description
                PotentialBenefits           = $contentRecommendation.potentialBenefits
                Tags                        = ($contentRecommendation.tags ?? @())
                RecommendationResourceType  = $contentRecommendation.recommendationResourceType
                RecommendationImpact        = $contentRecommendation.recommendationImpact
                AutomationAvailable         = $contentRecommendation.automationAvailable
                Query                       = $contentRecommendation.query
            }

            foreach ($learnMoreLink in ($contentRecommendation.learnMoreLinks ?? @())) {
                $recommendation.Links[$learnMoreLink.name] = $learnMoreLink.url
            }

            $recommendations += $recommendation
        }

        return $recommendations
    }
}

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
            QueryPaths = ($runbookHash.query_paths ?? $runbookHash.query_overrides ?? @())
            Parameters = ($runbookHash.parameters ?? @{})
            Variables  = ($runbookHash.variables ?? @{})
            Selectors  = ($runbookHash.selectors ?? @{})
            Groupings  = ($runbookHash.groupings ?? @{})
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
                        $check.GroupingName = $checkValue.grouping
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
