<#
.SYNOPSIS
    Represents an Azure Advisor recommendation resource object.

.DESCRIPTION
    The advisorResourceObj class encapsulates the details of an Azure Advisor recommendation resource. It contains properties such as recommendation ID, type, name, resource ID, subscription ID, resource group, location, category, impact, and description.

.PARAMETER Recommendation
    A recommendation object returned from Azure Advisor.
    The attributes of the object are used to populate the properties of the advisorResourceObj instance.

    [string] $recommendationId
    [string] $type
    [string] $name
    [string] $id
    [string] $subscriptionId
    [string] $resourceGroup
    [string] $location
    [string] $category
    [string] $impact
    [string] $description

.INPUTS
    None. You cannot pipe input to this class.

.OUTPUTS
    advisorResourceObj. An instance representing an Advisor recommendation.

.EXAMPLE
    $advisorRecommendation = [advisorResourceObj]::new($recommendation)
    This example creates a new instance of advisorResourceObj using a recommendation object.

.NOTES
    Author: Kyle Poineal
    Date: 2024-12-12
#>

class advisorResourceObj : IComparable, IEquatable[object] {
    [string] $recommendationId
    [string] $type
    [string] $name
    [string] $id
    [string] $subscriptionId
    [string] $resourceGroup
    [string] $location
    [string] $category
    [string] $impact
    [string] $description

    advisorResourceObj([PSObject]$psObject) {
        $this.RecommendationId = $psObject.recommendationId
        $this.Type = $psObject.type
        $this.Name = $psObject.name
        $this.Id = $psObject.id
        $this.SubscriptionId = $psObject.subscriptionId
        $this.ResourceGroup = $psObject.resourceGroup
        $this.Location = $psObject.location
        $this.Category = $psObject.category
        $this.Impact = $psObject.impact
        $this.Description = $psObject.description
    }

    [bool] Equals([object] $other) {
        if ($other -isnot [advisorResourceObj]) {
            throw "Expected an advisorResourceObj object"
        }
        foreach ($property in $this.PSObject.Properties.Name) {
            if ($this.$property -ne $other.$property) {
                return $false
            }
        }
        return $true
    }

    [int] CompareTo([object] $other) {
        if ($other -isnot [advisorResourceObj]) {
            throw "Expected an advisorResourceObj object"
        }
        foreach ($property in $this.PSObject.Properties.Name) {
            if ($this.$property -ne $other.$property) {
                return $this.$property.CompareTo($other.$property)
            }
        }
        return 0
    }
}
