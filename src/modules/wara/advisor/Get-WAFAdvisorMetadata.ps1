<#
.SYNOPSIS
    Retrieves metadata from Azure Advisor.

.DESCRIPTION
    The Get-WAFAdvisorMetadata function retrieves metadata from Azure Advisor using the Azure REST API.
    It uses an access token to authenticate and fetch the metadata.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.Object. The function returns the supported values from the Advisor metadata.

.EXAMPLE
    $AdvisorMetadata = Get-WAFAdvisorMetadata

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>
Function Get-WAFAdvisorMetadata {
    param($ResourceURL = "https://management.azure.com/" )

    # Get an access token for the Azure REST API
    $securetoken = Get-AzAccessToken -AsSecureString -ResourceUrl $ResourceURL -WarningAction SilentlyContinue

    # Convert the secure token to a plain text token
    $token = ConvertFrom-SecureString -SecureString $securetoken.token -AsPlainText

    # Create the authorization headers
    $authHeaders = @{
        'Authorization' = 'Bearer ' + $token
    }

    # Define the URI for the Advisor metadata
    $AdvisorMetadataURI = $ResourceUrl+"providers/Microsoft.Advisor/metadata?api-version=2023-01-01"

    # Invoke the REST API to get the metadata
    $r = Invoke-RestMethod -Uri $AdvisorMetadataURI -Headers $authHeaders -Method Get

    # Return the supported values from the metadata
    return $r.value.properties[0].supportedValues
}

