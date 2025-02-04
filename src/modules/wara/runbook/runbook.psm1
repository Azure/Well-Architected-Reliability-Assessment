using module ../utils/utils.psd1

class runbookCheck {
    [string]    $GroupingName
    [string]    $SelectorName
    [hashtable] $Parameters = @{}
    [string[]]  $Tags = @()
}

class runbookCheckSet {
    [hashtable] $Checks = @{}
}

class runbook {
    [string[]]  $QueryPaths = @()
    [hashtable] $Parameters = @{}
    [hashtable] $Variables = @{}
    [hashtable] $Selectors = @{}
    [hashtable] $Groupings = @{}
    [hashtable] $CheckSets = @{}
}

function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parmeter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )

    $runbookErrors = @()
    $runbookContent = (Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable)

    if ($runbook.query_paths -and $runbookContent.query_overrides) {
        $runbookErrors += "- [query_paths]: Runbook cannot include both [query_paths] and [query_overrides] sections."
        $runbookErrors += "- [query_overrides]: Runbook cannot include both [query_paths] and [query_overrides] sections."
    }
    elseif ($runbookContent.query_paths) {
        if (-not ($runbookContent.query_paths -is [array])) {
            $runbookErrors += (
                "- [query_paths]: If provided, [query_paths] must be an array of strings (folder paths.) `n" + 
                "  Example: `"query_paths`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
            )
        }
        else {
            foreach ($queryPath in $runbookContent.query_paths) {
                if (-not ($queryPath -is [string])) {
                    $runbookErrors += (
                        "- [query_paths]: If provided, [query_paths] must be an array of strings (folder paths.) `n" + 
                        "  Example: `"query_paths`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
                    )
                    break
                }
            }

            foreach ($queryPath in $runbookContent.query_paths) {
                if (($queryPath -is [string]) -and -not (Test-Path -Path $queryPath -PathType Container)) {
                    $runbookErrors += "- [query_paths]: Folder [$queryPath] not found."
                }
            }
        }
    }
    elseif ($runbookContent.query_overrides) {
        if (-not ($runbookContent.query_overrides -is [array])) {
            $runbookErrors += (
                "- [query_overrides]: If provided, [query_overrides] must be an array of strings (folder paths.) `n" + 
                "  Example: `"query_overrides`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
            )
        }
        else {
            foreach ($queryOverride in $runbookContent.query_overrides) {
                if (-not ($queryOverride -is [string])) {
                    $runbookErrors += (
                        "- [query_overrides]: If provided, [query_overrides] must be an array of strings (folder paths.) `n" + 
                        "  Example: `"query_overrides`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
                    )
                    break
                }
            }

            foreach ($queryOverride in $runbookContent.query_overrides) {
                if (($queryOverride -is [string]) -and -not (Test-Path -Path $queryOverride -PathType Container)) {
                    $runbookErrors += "- [query_overrides]: Folder [$queryOverride] not found."
                }
            }
        }
    }

    if ($runbookContent.parameters) {
        if (-not ($runbookContent.parameters -is [hashtable])) {
            $runbookErrors += (
                "- [parameters]: If provided, [parameters] must be a map of parameter names to values. `n" +
                "  Example: `"parameters`": { `"param1`": `"some text`", `"param2`": 2, `"param3`": true, ... }"
            )
        }
    }

    if (-not $runbookContent.selectors) {
        $runbookErrors += "- [selectors]: Runbook must include a [selectors] section."
    }
    elseif (-not ($runbookContent.selectors -is [hashtable])) {
        $runbookErrors += (
            "- [selectors]: [selectors] must be a map of selector names to selectors. `n" +
            "  Example: `"selectors`": { `"selector1`": `"[selector 1]`", `"selector2`": `"[selector 2]`", ... }"
        )
    }
    elseif ($runbookContent.selectors.Count -eq 0) {
        $runbookErrors += "- [selectors]: There must be at least one (1) selector defined."
    }
    else {
        foreach ($selectorKey in $runbookContent.selectors.Keys) {
            $selector = $runbookContent.selectors[$selectorKey]
            if (-not ($selectorKey -is [string]) -or -not ($selector -is [string])) {
                $runbookErrors += (
                    "- [selectors]: All selector names and values must be strings. `n" +
                    "  Example: `"selectors`": { `"selector1`": `"[selector 1]`", `"selector2`": `"[selector 2]`", ... }"
                )
                break
            }
        }
    }

    if ($runbookErrors.Count -gt 0) {
        
    }

    return $true
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

