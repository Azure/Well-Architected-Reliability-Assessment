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

function Test-RunbookParameters {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $RunbookContent
    )

    $errors = @()

    if ($RunbookContent.parameters) {
        if (-not ($RunbookContent.parameters -is [hashtable])) {
            $runbookErrors += (
                "- [parameters]: If provided, [parameters] must be a map of parameter names to values. `n" +
                "  Example: `"parameters`": { `"param1`": `"some text`", `"param2`": 2, `"param3`": true, ... }"
            )
        }
    }

    return $errors
}

function Test-RunbookVariables {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $RunbookContent
    )

    if ($RunbookContent.variables) {
        if (-not ($RunbookContent.variables -is [hashtable])) {
            $errors += (
                "- [variables]: If provided, [variables] must be a map of variable names to values. `n" +
                "  Example: `"variables`": { `"var1`": `"some text`", `"var2`": 2, `"var3`": true, ... }"
            )
        }
    }

    return $errors
}

function Test-RunbookSelectors {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $RunbookContent
    )

    $errors = @()

    if (-not $RunbookContent.selectors) {
        $errors += "- [selectors]: Runbook must include a [selectors] section."
    }
    elseif (-not ($RunbookContent.selectors -is [hashtable])) {
        $errors += (
            "- [selectors]: [selectors] must be a map of selector names to selectors. `n" +
            "  Example: `"selectors`": { `"selector1`": `"[selector 1]`", `"selector2`": `"[selector 2]`", ... }"
        )
    }
    elseif ($RunbookContent.selectors.Count -eq 0) {
        $errors += "- [selectors]: There must be at least one (1) selector defined."
    }
    else {
        foreach ($selectorKey in $RunbookContent.selectors.Keys) {
            $selector = $RunbookContent.selectors[$selectorKey]
            if (-not ($selectorKey -is [string]) -or -not ($selector -is [string])) {
                $errors += (
                    "- [selectors]: All selector names and values must be strings. `n" +
                    "  Example: `"selectors`": { `"selector1`": `"[selector 1]`", `"selector2`": `"[selector 2]`", ... }"
                )
                break
            }
        }
    }

    return $errors
}

function Test-RunbookQueryPaths {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $RunbookContent
    )

    $errors = @()

    if ($RunbookContent.query_paths -and $RunbookContent.query_overrides) {
        $errors += "- [query_paths]: Runbook cannot include both [query_paths] and [query_overrides] sections."
        $errors += "- [query_overrides]: Runbook cannot include both [query_paths] and [query_overrides] sections."
    }
    elseif ($RunbookContent.query_paths) {
        if (-not ($RunbookContent.query_paths -is [array])) {
            $errors += (
                "- [query_paths]: If provided, [query_paths] must be an array of strings (folder paths.) `n" +
                "  Example: `"query_paths`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
            )
        }
        else {
            foreach ($queryPath in $RunbookContent.query_paths) {
                if (-not ($queryPath -is [string])) {
                    $errors += (
                        "- [query_paths]: If provided, [query_paths] must be an array of strings (folder paths.) `n" +
                        "  Example: `"query_paths`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
                    )
                    break
                }
            }

            foreach ($queryPath in $RunbookContent.query_paths) {
                if (($queryPath -is [string]) -and -not (Test-Path -Path $queryPath -PathType Container)) {
                    $errors += "- [query_paths]: Folder [$queryPath] not found."
                }
            }
        }
    }
    elseif ($RunbookContent.query_overrides) {
        if (-not ($RunbookContent.query_overrides -is [array])) {
            $errors += (
                "- [query_overrides]: If provided, [query_overrides] must be an array of strings (folder paths.) `n" +
                "  Example: `"query_overrides`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
            )
        }
        else {
            foreach ($queryOverride in $RunbookContent.query_overrides) {
                if (-not ($queryOverride -is [string])) {
                    $errors += (
                        "- [query_overrides]: If provided, [query_overrides] must be an array of strings (folder paths.) `n" +
                        "  Example: `"query_overrides`": [ `"\path\to\query\folder`", `"\path\to\another\query\folder`", ... ]"
                    )
                    break
                }
            }

            foreach ($queryOverride in $RunbookContent.query_overrides) {
                if (($queryOverride -is [string]) -and -not (Test-Path -Path $queryOverride -PathType Container)) {
                    $errors += "- [query_overrides]: Folder [$queryOverride] not found."
                }
            }
        }
    }

    return $errors
}

function Test-RunbookFile {
    [CmdletBinding()]
    param (
        [Parmeter(Mandatory = $true)]
        [ValidateScript({ Test-FileExists $_ })]
        [string] $Path
    )
    $errors = @()

    $runbookContent = (Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable)

    $errors += (Test-RunbookQueryPaths -RunbookContent $runbookContent)
    $errors += (Test-RunbookParameters -RunbookContent $runbookContent)
    $errors += (Test-RunbookVariables  -RunbookContent $runbookContent)
    $errors += (Test-RunbookSelectors  -RunbookContent $runbookContent)

    if ($errors.Count -gt 0) {
        throw "Runbook file [$Path] is invalid:`n$($errors -join "`n")"
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

