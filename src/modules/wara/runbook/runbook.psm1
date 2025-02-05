using module ../utils/utils.psd1

class runbookCheck {
    [string] $GroupingName
    [string] $SelectorName
    [hashtable] $Parameters = @{}
    [string[]] $Tags = @()
}

class runbookCheckSet {
    [hashtable] $Checks = @{}
}

class runbook {
    [string[]] $QueryPaths = @()
    [hashtable] $Parameters = @{}
    [hashtable] $Variables = @{}
    [hashtable] $Selectors = @{}
    [hashtable] $Groupings = @{}
    [hashtable] $CheckSets = @{}
}

class selectorReview {
    [hashtable] $Selectors = @{}
}

class selectedResourceSet {
    [string] $Selector
    [string] $SelectorResourceGraphQuery
    [selectedResource[]] $Resources = @{}
}

class selectedResource {
    [string] $ResourceId
    [string] $ResourceType
    [string] $ResourceName
    [string] $ResourceGroupName
}

class runbookFactory {
    [runbook] parseRunbookContent([string] $runbookContent) {
        $runbook = [runbook]::new()
        $runbookTable = ($runbookContent | ConvertFrom-Json -AsHashtable)
        $runbook.QueryPaths = ($runbookTable.query_paths ?? $runbookTable.query_overrides ?? @())
        $runbook.Parameters = ($runbookTable.parameters ?? @{})
        $runbook.Variables = ($runbookTable.variables ?? @{})
        $runbook.Selectors = ($runbookTable.selectors ?? @{})
        $runbook.Groupings = ($runbookTable.groupings ?? @{})

        foreach ($checkSetKey in $runbookTable.checks.Keys) {
            $checkSet = [runbookCheckSet]::new()
            $checkSetTable = $runbookTable.checks[$checkSetKey]

            foreach ($checkKey in $checkSetTable.Keys) {
                $check = [runbookCheck]::new()
                $checkValue = $checkSetTable[$checkKey]

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

function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parmeter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    # Hard-coded schema to be replaced with public runbook schema.
    $runbookSchema = @"
{
  "title": "Runbook",
  "description": "A Well-Architected Reliability Assessment (WARA) runbook",
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
"@

    $errors = @()
    $fileContent = Get-Content -Path $Path -Raw

    if (-not ($fileContent | Test-Json)) {
        $errors = "- Runbook file [$Path] is not a valid JSON file."
    }
    elseif (-not ($fileContent | Test-Json -Schema $runbookSchema)) {
        $errors = "- Runbook file [$Path] does not match the runbook JSON schema."
    }
    else {

    }

    return $true
}

function Invoke-RunbookSelectorReview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [runbook] $Runbook
    )


}

function Read-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    Test-RunbookFile -Path $Path

    $runbook = [runbook]::new()
    $runbookContent = (Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable)
    $runbook.QueryPaths = ($runbookContent.query_paths ?? $runbookContent.query_overrides ?? @())
    $runbook.Parameters = ($runbookContent.parameters ?? @{})
    $runbook.Variables = ($runbookContent.variables ?? @{})
    $runbook.Selectors = ($runbookContent.selectors ?? @{})
    $runbook.Groupings = ($runbookContent.groupings ?? @{})

    foreach ($checkSetKey in $runbookContent.checks.Keys) {
        $checkSet = [runbookCheckSet]::new()
        $checkSetContent = $runbookContent.checks[$checkSetKey]

        foreach ($checkKey in $checkSetContent.Keys) {
            $check = [runbookCheck]::new()
            $checkContent = $checkSetContent[$checkKey]

            switch ($checkContent.GetType().Name.ToLower()) {
                "string" {
                    $check.SelectorName = $checkContent
                }
                "orderedhashtable" {
                    $check.GroupingName = $checkContent.grouping
                    $check.SelectorName = $checkContent.selector
                    $check.Parameters = ($checkContent.parameters ?? @{})
                    $check.Tags = ($checkContent.tags ?? @())
                }
            }

            $checkSet.Checks[$checkKey] = $check
        }

        $runbook.CheckSets[$checkSetKey] = $checkSet
    }

    return $runbook
}

function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    $errors = @()
    $runbookJson = Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable


}

