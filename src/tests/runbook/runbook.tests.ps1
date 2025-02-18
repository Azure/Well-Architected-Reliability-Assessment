using module ../../modules/wara/utils/utils.psd1

BeforeAll {
    $rootPath = "$PSScriptRoot/.."

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

    $subscriptionIds = @("00000000-0000-0000-0000-000000000000")

    function Test-RunbookCorrectlyParsed() {
        param(
            [Parameter(Mandatory = $true)]
            [hashtable] $SourceRunbookHash,

            [Parameter(Mandatory = $true)]
            [Runbook] $ParsedRunbook
        )

        $SourceRunbookHash.parameters.Keys.Count | Should -Be $ParsedRunbook.Parameters.Keys.Count

        foreach ($hashParameterKey in $SourceRunbookHash.parameters.Keys) {
            $ParsedRunbook.Parameters.Keys | Should -Contain $hashParameterKey

            if ($ParsedRunbook.Parameters.ContainsKey($hashParameterKey)) {
                $hashParameter = $SourceRunbookHash.parameters[$hashParameterKey]
                $ParsedRunbook.Parameters[$hashParameterKey] | Should -Be $hashParameter
            }
        }

        $SourceRunbookHash.variables.Keys.Count | Should -Be $ParsedRunbook.Variables.Keys.Count

        foreach ($hashVariableKey in $SourceRunbookHash.variables.Keys) {
            $ParsedRunbook.Variables.Keys | Should -Contain $hashVariableKey

            if ($ParsedRunbook.Variables.ContainsKey($hashVariableKey)) {
                $hashVariable = $SourceRunbookHash.variables[$hashVariableKey]
                $ParsedRunbook.Variables[$hashVariableKey] | Should -Be $hashVariable
            }
        }

        $SourceRunbookHash.selectors.Keys.Count | Should -Be $ParsedRunbook.Selectors.Keys.Count

        foreach ($hashSelectorKey in $SourceRunbookHash.selectors.Keys) {
            $ParsedRunbook.Selectors.Keys | Should -Contain $hashSelectorKey

            if ($ParsedRunbook.Selectors.ContainsKey($hashSelectorKey)) {
                $hashSelector = $SourceRunbookHash.selectors[$hashSelectorKey]
                $ParsedRunbook.Selectors[$hashSelectorKey] | Should -Be $hashSelector
            }
        }

        $SourceRunbookHash.checks.Keys.Count | Should -Be $ParsedRunbook.CheckSets.Keys.Count

        foreach ($hashCheckSetKey in $SourceRunbookHash.checks.Keys) {
            $ParsedRunbook.CheckSets.Keys | Should -Contain $hashCheckSetKey

            if ($ParsedRunbook.CheckSets.ContainsKey($hashCheckSetKey)) {
                $hashCheckSet = $SourceRunbookHash.checks[$hashCheckSetKey]
                $runbookCheckSet = $ParsedRunbook.CheckSets[$hashCheckSetKey]

                $hashCheckSet.Keys.Count | Should -Be $runbookCheckSet.Checks.Keys.Count

                foreach ($hashCheckKey in $hashCheckSet.Keys) {
                    $runbookCheckSet.Checks.Keys | Should -Contain $hashCheckKey

                    if ($runbookCheckSet.Checks.ContainsKey($hashCheckKey)) {
                        $hashCheck = $hashCheckSet[$hashCheckKey]
                        $runbookCheck = $runbookCheckSet.Checks[$hashCheckKey]

                        switch ($hashCheck.GetType().Name.ToLower()) {
                            "string" {
                                $hashCheck | Should -Be $runbookCheck.SelectorName
                            }
                            "orderedhashtable" {
                                $hashCheck.selector | Should -Be $runbookCheck.SelectorName
                                $hashCheck.parameters.Keys.Count | Should -Be $runbookCheck.Parameters.Keys.Count

                                foreach ($hashParameterKey in $hashCheck.parameters.Keys) {
                                    $runbookCheck.Parameters.Keys | Should -Contain $hashParameterKey

                                    if ($runbookCheck.Parameters.ContainsKey($hashParameterKey)) {
                                        $hashParameter = $hashCheck.parameters[$hashParameterKey]
                                        $runbookCheck.Parameters[$hashParameterKey] | Should -Be $hashParameter
                                    }
                                }

                                $hashCheck.tags.Count | Should -Be $runbookCheck.Tags.Count

                                foreach ($hashTag in $hashCheck.tags) {
                                    $runbookCheck.Tags | Should -Contain $hashTag
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

Describe "Get-RunbookSchema" {
    It "Should return the runbook JSON schema" {
        $schema = Get-RunbookSchema
        $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
        $runbookFileContents = Get-Content -Path $runbookPath -Raw

        $schema | Should -Not -BeNullOrEmpty
        $($runbookFileContents | Test-Json -Schema $schema) | Should -Be $true
    }
}

Describe "New-RunbookFactory" {
    It "Should return a new RunbookFactory object" {
        $factory = New-RunbookFactory

        $factory.GetType().Name.ToLower() | Should -Be "runbookfactory"
    }
}

Describe "New-RecommendationFactory" {
    It "Should return a new RecommendationFactory object" {
        $factory = New-RecommendationFactory

        $factory.GetType().Name.ToLower() | Should -Be "recommendationfactory"
    }
}

Describe "New-RunbookCheckSet" {
    It "Should return a new RunbookCheckSet object" {
        $checkSet = New-RunbookCheckSet

        $checkSet.GetType().Name.ToLower() | Should -Be "runbookcheckset"
        $checkSet.Checks.Count | Should -Be 0
    }
}

Describe "New-RunbookCheck" {
    It "Should return a new RunbookCheck object" {
        $check = New-RunbookCheck

        $check.GetType().Name.ToLower() | Should -Be "runbookcheck"
        $check.SelectorName | Should -Be $null
        $check.Parameters.Count | Should -Be 0
        $check.Tags.Count | Should -Be 0
    }
}

Describe "New-Runbook" {
    Context "When provided with runbook JSON contents" {
        It "Should return a corresponding Runbook object" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
            $runbookFileContents = Get-Content -Path $runbookPath -Raw
            $runbookHash = $runbookFileContents | ConvertFrom-Json -AsHashtable
            $parsedRunbook = New-Runbook -FromJson $runbookFileContents

            Test-RunbookCorrectlyParsed -SourceRunbookHash $runbookHash -ParsedRunbook $parsedRunbook
        }
    }
    Context "When provided with runbook JSON file path" {
        It "Should return a corresponding Runbook object" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
            $runbookHash = Get-Content -Path $runbookPath -Raw | ConvertFrom-Json -AsHashtable
            $parsedRunbook = New-Runbook -FromJsonFile $runbookPath

            Mock Test-RunbookFile { $true } -ModuleName $moduleUnderTest.Name

            Test-RunbookCorrectlyParsed -SourceRunbookHash $runbookHash -ParsedRunbook $parsedRunbook
        }
    }
    Context "When provided with invalid runobok JSON file path" {
        It "Should throw an error indicating that the file is invalid" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/not_a_json_file.txt"

            { New-Runbook -FromJsonFile $runbookPath } | Should -Throw
        }
    }
    Context "When provided with both runbook JSON contents and file path" {
        It "Should throw an error indicating that both parameters can not be used at the same time" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
            $runbookFileContents = Get-Content -Path $runbookPath -Raw
            $expError = "*Cannot specify both -FromJson and -FromJsonFile*"

            { New-Runbook -FromJson $runbookFileContents -FromJsonFile $runbookPath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When no parameters are provided" {
        It "Should return a new Runbook" {
            $runbook = New-Runbook

            $runbook.GetType().Name.ToLower() | Should -Be "runbook"

            $runbook.QueryPaths.Count | Should -Be 0
            $runbook.Parameters.Count | Should -Be 0
            $runbook.Variables.Count | Should -Be 0
            $runbook.Selectors.Count | Should -Be 0
            $runbook.CheckSets.Count | Should -Be 0
        }
    }
}



Describe "Test-RunbookFile" {
    Context "When the file doesn't contain valid JSON" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/not_a_json_file.txt"
            $expError = "*is not a valid JSON file*"

            { Test-RunbookFile -Path $filePath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When the file doesn't adhere to the runbook JSON schema" {
        It "Should throw an error indicating so" {
            $filepath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/invalid_schema.json"
            $expError = "*does not adhere to the runbook JSON schema*"

            { Test-RunbookFile -Path $filepath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there are no [selectors] defined" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/no_checks_or_selectors.json"
            $expError = "*At least one (1) selector is required*"

            { Test-RunbookFile -Path $filePath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there are no [checks] defined" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/no_checks_or_selectors.json"
            $expError = "*At least one (1) check set is required*"

            { Test-RunbookFile -Path $filePath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When a check references an undeclared selector" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/undeclared_selector.json"
            $expError = "*references a selector that does not exist*"

            { Test-RunbookFile -Path $filePath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
    Context "When there's an invalid query path" {
        It "Should throw an error indicating so" {
            $filePath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/invalid_query_path.json"
            $expError = "*does not exist or is not a directory*"

            { Test-RunbookFile -Path $filePath } |
            Should -Throw -ExpectedMessage $expError
        }
    }
}

Describe "Invoke-RunbookQueryLoop" {
    Context "When provided with a valid runbook and corresponding recommendations" {
        It "Should run all checks defined in the runbook and return the results" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
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
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
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
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/undeclared_selector.json"
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
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/invalid/unknown_recommendation.json"
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
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
            $runbookHash = Get-Content -Path $runbookPath -Raw | ConvertFrom-Json -AsHashtable
            $parsedRunbook = Read-RunbookFile -Path $runbookPath

            Test-RunbookCorrectlyParsed -SourceRunbookHash $runbookHash -ParsedRunbook $parsedRunbook
        }
    }
}

Describe "Build-RunbookSelectorReview" {
    Context "When provided with a valid runbook" {
        It "Should list all selectors and corresponding selected resources" {
            $runbookPath = "$($moduleUnderTest.Paths.Data)/runbooks/valid/runbook.json"
            $resourcesPath = "$($moduleUnderTest.Paths.Data)/selected_resources.json"

            $runbook = $runbookFactory.ParseRunbookFile($runbookPath)
            $resources = @(Get-Content -Path $resourcesPath -Raw | ConvertFrom-Json)

            Mock Invoke-WAFQuery { $resources } -ModuleName $moduleUnderTest.Name

            $review = Build-RunbookSelectorReview -Runbook $runbook -SubscriptionIds $subscriptionIds

            $review.Count | Should -Be $runbook.Selectors.Keys.Count

            foreach ($selectorKey in $runbook.Selectors.Keys) {
                $selectorResources = $resources | Where-Object { $_.selector -eq $selectorKey }

                $selectorResources.Count | Should -Be $review[$selectorKey].Count

                foreach ($resource in $selectorResources) {
                    $review[$selectorKey] | Should -Contain $resource
                }
            }
        }
    }
}
