using module ../../modules/wara/utils/utils.psd1

BeforeAll {
    $root = "$PSScriptRoot/.."

    $moduleUnderTest = @{
        Name  = "runbook"
        Paths = @{
            Classes = "$root/../modules/wara/runbook/runbook.classes.ps1"
            Module  = "$root/../modules/wara/runbook/runbook.psd1"
            Data    = "$root/data/runbook"
        }
    }

    Import-Module $moduleUnderTest.Paths.Module -Force

    . $moduleUnderTest.Paths.Classes

    $recommendationFactory = New-RecommendationFactory
    $runbookFactory = New-RunbookFactory

    $subscriptionIds = @("00000000-0000-0000-0000-000000000000")
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
    Context "When provided with a valid runbook and corresponding recommendations" {
        It "Should run all checks defined in the runbook and return the results" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbook.json"
            $recommendationsPath = "$($moduleUnderTest.Paths.Data)/recommendations.json"
            $queriesPath = "$($moduleUnderTest.Paths.Data)/runbook_queries.json"
            $queryResultsPath = "$($moduleUnderTest.Paths.Data)/runbook_query_results.json"

            $runbook = $runbookFactory.ParseRunbookFile($runbookPath)
            $recommendations = $recommendationFactory.ParseRecommendationsFile($recommendationsPath)
            $queries = @(Get-Content -Path $queriesPath -Raw | ConvertFrom-Json)
            $queryResults = @(Get-Content -Path $queryResultsPath -Raw | ConvertFrom-Json)

            Mock Build-RunbookQueries { $queries } -ModuleName $moduleUnderTest.Name
            Mock Invoke-WAFQuery { $queryResults } -ModuleName $moduleUnderTest.Name

            $results = Invoke-RunbookQueryLoop `
                -Runbook $runbook `
                -Recommendations $recommendations `
                -SubscriptionIds $subscriptionIds

            $resultsHash = @{}
            $results | ForEach-Object { $resultsHash[$_.recommendationId] = $_ }

            $queryResultsHash = @{}
            $queryResults | ForEach-Object { $queryResultsHash[$_.recommendationId] = $_ }

            $results.Count | Should -Be $queryResults.Count

            foreach ($resultKey in $resultsHash.Keys) {
                $result = $resultsHash[$resultKey]
                $queryResult = $queryResultsHash[$resultKey]

                $result | Should -Be $queryResult
            }
        }
    }
}

Describe "Build-RunbookQueries" {
    Context "When provided with a valid runbook and corresponding recommendations" {
        It "Should build a query for each check defined in the runbook" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbook.json"
            $recommendationsPath = "$($moduleUnderTest.Paths.Data)/recommendations.json"
            $queriesPath = "$($moduleUnderTest.Paths.Data)/runbook_queries.json"

            $runbook = $runbookFactory.ParseRunbookFile($runbookPath)
            $recommendations = $recommendationFactory.ParseRecommendationsFile($recommendationsPath)
            $queries = @(Get-Content -Path $queriesPath -Raw | ConvertFrom-Json)
            $results = Build-RunbookQueries -Runbook $runbook -Recommendations $recommendations

            $results.Count | Should -Be $queries.Count

            for ($i = 0; $i -lt $results.Count; $i++) {
                $query = $queries[$i]
                $result = $results[$i]

                $result.CheckSetName | Should -Be $query.CheckSetName
                $result.CheckName | Should -Be $query.CheckName
                $result.Query | Should -Be $query.Query
                $result.Tags | Should -Be $query.Tags
            }
        }
    }
    Context "When provided with an invalid runbook due to an undeclared selector" {
        It "Should throw an error indicating so" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/undeclared_selector.json"
            $recommendationsPath = "$($moduleUnderTest.Paths.Data)/recommendations.json"
            $expError = "*references a selector that does not exist*"

            $runbook = $runbookFactory.ParseRunbookFile($runbookPath)
            $recommendations = $recommendationFactory.ParseRecommendationsFile($recommendationsPath)

            { Build-RunbookQueries -Runbook $runbook -Recommendations $recommendations } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When provided with an invalid runbook due to an unknown recommendation" {
        It "Should throw an error indicating so" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/invalid_runbooks/unknown_recommendation.json"
            $recommendationsPath = "$($moduleUnderTest.Paths.Data)/recommendations.json"
            $expError = "*recommendation not found*"

            $runbook = $runbookFactory.ParseRunbookFile($runbookPath)
            $recommendations = $recommendationFactory.ParseRecommendationsFile($recommendationsPath)

            { Build-RunbookQueries -Runbook $runbook -Recommendations $recommendations } |
            Should -Throw -ExpectedMessage $expError
        }
    }
}

Describe "Read-RunbookFile" {
    Context "When provided with a valid runbook file" {
        It "Should return a corresponding Runbook object" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbook.json"
            $runbookHash = (Get-Content -Path $runbookPath -Raw | ConvertFrom-Json -AsHashtable)

            $runbook = $(Read-RunbookFile -Path $runbookPath)

            foreach ($hashParameterKey in $runbookHash.parameters.Keys) {
                $hashParameter = $runbookHash.parameters[$hashParameterKey]
                $runbook.Parameters.Keys | Should -Contain $hashParameterKey

                if ($runbook.Parameters.ContainsKey($hashParameterKey)) {
                    $runbook.Parameters[$hashParameterKey] | Should -Be $hashParameter
                }
            }

            foreach ($hashVariableKey in $runbookHash.variables.Keys) {
                $hashVariable = $runbookHash.variables[$hashVariableKey]
                $runbook.Variables.Keys | Should -Contain $hashVariableKey

                if ($runbook.Variables.ContainsKey($hashVariableKey)) {
                    $runbook.Variables[$hashVariableKey] | Should -Be $hashVariable
                }
            }

            foreach ($hashSelectorKey in $runbookHash.selectors.Keys) {
                $hashSelector = $runbookHash.selectors[$hashSelectorKey]
                $runbook.Selectors.Keys | Should -Contain $hashSelectorKey

                if ($runbook.Selectors.ContainsKey($hashSelectorKey)) {
                    $runbook.Selectors[$hashSelectorKey] | Should -Be $hashSelector
                }
            }

            foreach ($hashCheckSetKey in $runbookHash.checks.Keys) {
                $hashCheckSet = $runbookHash.checks[$hashCheckSetKey]
                $runbook.CheckSets.Keys | Should -Contain $hashCheckSetKey

                if ($runbook.CheckSets.ContainsKey($hashCheckSetKey)) {
                    foreach ($hashCheckKey in $hashCheckSet.Keys) {
                        $hashCheck = $hashCheckSet[$hashCheckKey]
                        $runbook.CheckSets[$hashCheckSetKey].Checks.Keys | Should -Contain $hashCheckKey

                        if ($runbook.CheckSets[$hashCheckSetKey].Checks.ContainsKey($hashCheckKey)) {
                            $runbookCheck = $runbook.CheckSets[$hashCheckSetKey].Checks[$hashCheckKey]

                            $runbookCheck.SelectorName | Should -Be $hashCheck.selector
                            $runbookCheck.Tags | Should -Be $hashCheck.tags
                        }
                    }
                }
            }
        }
    }
}
