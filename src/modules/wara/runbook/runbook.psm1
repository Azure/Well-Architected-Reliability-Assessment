using module ../utils/utils.psd1

class runbookCheck {
    [string]    $GroupingName
    [string]    $SelectorName
    [hashtable] $Parameters
    [string[]]  $Tags
}

class runbookCheckSet {
    [hashtable] $Checks
}

class runbook {
    [string[]]  $QueryPaths
    [hashtable] $Parameters
    [hashtable] $Variables
    [hashtable] $Selectors
    [hashtable] $Groupings
    [hashtable] $CheckSets
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
    $runbookContent = Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable

    $runbook.QueryPaths = ($runbookFile.query_paths ?? $runbookFile.query_overrides ?? @())
    $runbook.Parameters = ($runbookFile.parameters ?? @{})
    $runbook.Variables = ($runbookFile.variables ?? @{})
    $runbook.Selectors = ($runbookFile.selectors ?? @{})
    $runbook.Groupings = ($runbookFile.groupings ?? @{})
    $runbook.CheckSets = @{}

    foreach ($checkSetKey in $runbookContent.checks.Keys) {
        $checkSet = [runbookCheckSet]::new()
        $checkSetContent = $runbookContent.checks[$checkSetKey]

        foreach ($checkKey in $checkSetContent.Keys) {
            $check = [runbookCheck]::new()
            $checkContent = $checkSetContent[$checkKey]

            switch ($checkContent.GetType().Name.ToLower()) {
                "string" {
                    $check.GroupingName = $null
                    $check.SelectorName = $checkContent
                    $check.Parameters = @{}
                    $check.Tags = @()
                }
                "orderedhashtable" {
                    $check.GroupingName = $checkContent.grouping
                    $check.SelectorName = $checkContent.selector
                    $check.Parameters = ($checkContent.parameters ?? @{})
                    $check.Tags = ($checkContent.tags ?? @())
                }
            }
        }

        $runbook.CheckSets[$checkSetKey] = $checkSet
    } 
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

    if ($runbookJson.ContainsKey("query_overrides") -and $runbookJson.ContainsKey("query_paths")) {
        $errors += "-> [query_paths (query_overrides)]: Runbooks may have a [query_overrides] or [query_paths] section, but not both."
    }

    foreach ($queryPath in ($runbookJson.query_paths ?? $runbookJson.query_overrides ?? @())) {
        if (-not (Test-Path -Path $queryPath -PathType Container)) {
            $errors += "-> [query_paths (query_overrides)]: Folder [$queryPath] not found."
        }
    }

    if (($runbookJson.selectors ?? @()).Count -eq 0) {
        $errors += "-> [selectors]: At least one (1) selector must be defined."
    }

    if (($runbookJson.checks ?? @()).Count -eq 0) {
        $errors += "-> [checks]: At least one (1) check set must be defined."
    }
    else {
        foreach ($checkSetName in $runbookJson.checks.Keys) {
            $checkSet = $runbookJson.checks[$checkSetName]

            if ($checkSet.Count -eq 0) {
                $errors += "-> [checks]: Check set [$checkSetName] must define at least one (1) check."
            }

            foreach ($checkName in $checkSet.Keys) {
                $check = $checkSet[$checkName]  
                
                if ($check.GetType().Name.ToLower() -eq 'orderedhashtable') {
                    if (-not $check.ContainsKey("selector")) {
                        $errors += "-> [checks]: Check set [$checkSetName] check [$checkName] must define a [selector]."
                    }
                }
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw "Runbook [$Path] is invalid:`n$($errors -join "`n")"
    }
    
    return $true
}

