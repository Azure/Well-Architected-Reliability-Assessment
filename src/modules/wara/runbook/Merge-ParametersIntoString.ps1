<#
.FUNCTION
    Merge-ParametersIntoString

.SYNOPSIS
    Replaces placeholders in a string with parameter values.

.DESCRIPTION
    The `Merge-ParametersIntoString` function iterates through a hashtable of parameters
    and replaces placeholders in the input string with corresponding values.
    Placeholders must follow the `{{Key}}` format.

.PARAMETER Parameters
    A hashtable containing key-value pairs for replacement.

.PARAMETER Into
    The string containing placeholders to be replaced.

.OUTPUTS
    [string]
    A string with placeholders replaced by their corresponding values.

.EXAMPLE
    $params = @{ "Region" = "eastus"; "Env" = "Production" }
    $result = Merge-ParametersIntoString -Parameters $params -Into "Deploying to {{Region}} in {{Env}}."

    Returns: "Deploying to eastus in Production."

.NOTES
    - Only placeholders matching keys in the hashtable are replaced.
    - Uses simple string replacement logic.

    Author: Casey Watson
    Date: 2025-02-27
#>
function Merge-ParametersIntoString {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable] $Parameters,

        [Parameter(Mandatory = $true)]
        [string] $Into
    )

    foreach ($parameterKey in $Parameters.Keys) {
        $Into = $Into.Replace("{{$parameterKey}}", $Parameters[$parameterKey])
    }

    return $Into
}
