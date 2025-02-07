BeforeAll {
    $rootPath = "$PSScriptRoot/.."
    $dataPath = "$rootPath/data/runbook"
    $modulePath = "$rootPath/../modules/wara/runbook/runbook.psd1"

    Import-Module -Name $modulePath -Force
}

Describe "Test-RunbookFile" {
    Context "When the file doesn't contain valid JSON" {
        It "Should throw an error indicating so" {
            $filePath = "$dataPath/invalid_runbooks/not_a_json_file.txt"
            $expError = "*is not a valid JSON file*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When the file doesn't adhere to the runbook JSON schema" {
        It "Should throw an error indicating so" {
            $filepath = "$dataPath/invalid_runbooks/invalid_schema.json"
            $expError = "*does not adhere to the runbook JSON schema*"

            { Test-RunbookFile -Path $filepath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there are no [selectors] defined" {
        It "Should throw an error indicating so" {
            $filePath = "$dataPath/invalid_runbooks/no_checks_or_selectors.json"
            $expError = "*At least one (1) selector is required*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there are no [checks] defined" {
        It "Should throw an error indicating so" {
            $filePath = "$dataPath/invalid_runbooks/no_checks_or_selectors.json"
            $expError = "*At least one (1) check set is required*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When a check references an undeclared selector" {
        It "Should throw an error indicating so" {
            $filePath = "$dataPath/invalid_runbooks/undeclared_selector.json"
            $expError = "*references a selector that does not exist*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When a check references an undeclared grouping" {
        It "Should throw an error indicating so" {
            $filePath = "$dataPath/invalid_runbooks/undeclared_grouping.json"
            $expError = "*references a grouping that does not exist*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there's an invalid query path" {
        It "Should throw an error indicating so" {
            $filePath = "$dataPath/invalid_runbooks/invalid_query_path.json"
            $expError = "*does not exist or is not a directory*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
}
