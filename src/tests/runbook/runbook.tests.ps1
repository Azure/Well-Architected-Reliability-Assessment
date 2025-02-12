using module ../../modules/wara/utils/utils.psd1

BeforeAll {
    $rootPath = "$PSScriptRoot/.."
    $subscriptionIds = @("00000000-0000-0000-0000-000000000000")

    $moduleUnderTest = @{
        Name  = "runbook"
        Paths = @{
            Classes = "$rootPath/../modules/wara/runbook/runbook.classes.ps1"
            Module  = "$rootPath/../modules/wara/runbook/runbook.psd1"
            Data    = "$rootPath/data/runbook"
        }
    }

    Import-Module $moduleUnderTest.Paths.Module -Force

    . $moduleUnderTest.Paths.Classes

    $recommendationFactory = New-RecommendationFactory
    $runbookFactory = New-RunbookFactory
}

Describe "Test-RunbookFile" {
    Context "When the file doesn't contain valid JSON" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/not_a_json_file.txt"
            $expError = "*is not a valid JSON file*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When the file doesn't adhere to the runbook JSON schema" {
        It "Should throw an error indicating so" {
            $filepath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/invalid_schema.json"
            $expError = "*does not adhere to the runbook JSON schema*"

            { Test-RunbookFile -Path $filepath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there are no [selectors] defined" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/no_checks_or_selectors.json"
            $expError = "*At least one (1) selector is required*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there are no [checks] defined" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/no_checks_or_selectors.json"
            $expError = "*At least one (1) check set is required*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When a check references an undeclared selector" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/undeclared_selector.json"
            $expError = "*references a selector that does not exist*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When a check references an undeclared grouping" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/undeclared_grouping.json"
            $expError = "*references a grouping that does not exist*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there's an invalid query path" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/invalid_query_path.json"
            $expError = "*does not exist or is not a directory*"

            { Test-RunbookFile -Path $filePath } | Should -Throw -ExpectedMessage $expError
        }
    }
}

Describe "Invoke-RunbookQueryLoop" {
    Context "When provided with a valid runbook" {
        It "Should run all checks defined in the runbook and return the results" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbook.json"
            $recommendationsPath = "$($moduleUnderTest.Paths.Data)/recommendations.json"
            $queriesPath = "$($moduleUnderTest.Paths.Data)/runbook_queries.json"
            $queryResultsPath = "$($moduleUnderTest.Paths.Data)/runbook_query_results.json"

            $runbook = $runbookFactory.ParseRunbookFile($runbookPath)
            $recommendations = $recommendationFactory.ParseRecommendationsFile($recommendationsPath)
            $queries = (Get-Content -Path $queriesPath -Raw | ConvertFrom-Json -Depth 5 -AsHashtable)
            $queryResults = (Get-Content -Path $queryResultsPath -Raw | ConvertFrom-Json -Depth 5)

            Mock Build-RunbookQueries { $queries } -ModuleName $moduleUnderTest.Name
            Mock Invoke-WAFQuery { $queryResults } -ModuleName $moduleUnderTest.Name

            $results = Invoke-RunbookQueryLoop -Runbook $runbook -Recommendations $recommendations -SubscriptionIds $subscriptionIds
        }
    }
}
