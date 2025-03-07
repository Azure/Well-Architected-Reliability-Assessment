# WARA Module Classes

This document describes the PowerShell classes used within the WARA module.

## aprlResourceTypeObj

### SYNOPSIS

Represents a resource type object for APRL.

### DESCRIPTION

The `aprlResourceTypeObj` class encapsulates the details of a resource type in APRL, including the number of resources, availability in APRL/ADVISOR, assessment owner, status, and notes.

### PROPERTIES

- **Resource Type**: The type of the resource.
- **Number Of Resources**: The number of resources of this type.
- **Available in APRL/ADVISOR?**: Indicates whether the resource type is available in APRL or ADVISOR.
- **Assessment Owner**: The owner of the assessment.
- **Status**: The status of the resource type.
- **Notes**: Additional notes about the resource type.

## resourceTypeFactory

### SYNOPSIS

Factory class to create resource type objects.

### DESCRIPTION

The `resourceTypeFactory` class is responsible for creating instances of `aprlResourceTypeObj` based on impacted resources and types not in APRL or ADVISOR.

### PROPERTIES

- **impactedResourceObj**: The impacted resource objects.
- **TypesNotInAPRLOrAdvisor**: Resource types that we want to create a recommendation for but do not have a recommendation for.

### CONSTRUCTORS

```powershell
resourceTypeFactory([PSObject]$impactedResourceObj, [PSObject]$TypesNotInAPRLOrAdvisor)
```

### METHODS

```powershell
[object[]] createResourceTypeObjects()
```

Creates resource type objects based on the impacted resources and types not in APRL or ADVISOR.

## aprlResourceObj

### SYNOPSIS

Represents an APRL resource object.

### DESCRIPTION

The `aprlResourceObj` class encapsulates the details of an APRL resource, including validation action, recommendation ID, name, ID, type, location, subscription ID, resource group, parameters, check name, and selector.

### PROPERTIES

- **validationAction**: The validation action for the resource.
- **recommendationId**: The recommendation ID for the resource.
- **name**: The name of the resource.
- **id**: The ID of the resource.
- **type**: The type of the resource.
- **location**: The location of the resource.
- **subscriptionId**: The subscription ID of the resource.
- **resourceGroup**: The resource group of the resource.
- **param1**: Additional parameter 1.
- **param2**: Additional parameter 2.
- **param3**: Additional parameter 3.
- **param4**: Additional parameter 4.
- **param5**: Additional parameter 5.
- **checkName**: The check name for the resource.
- **selector**: The selector for the resource.

## impactedResourceFactory

### SYNOPSIS

Factory class to create impacted resource objects.

### DESCRIPTION

The `impactedResourceFactory` class is responsible for creating instances of `aprlResourceObj` based on impacted resources, all resources, and recommendation objects.

### PROPERTIES

- **impactedResources**: The impacted resources.
- **allResources**: All resources.
- **RecommendationObject**: The recommendation object.

### CONSTRUCTORS

```powershell
impactedResourceFactory([PSObject]$impactedResources, [hashtable]$allResources, [hashtable]$RecommendationObject)
```

### METHODS

```powershell
[object[]] createImpactedResourceObjects()
```

Creates and returns an array of `aprlResourceObj` instances based on the impacted resources, all resources, and recommendation objects.

## validationResourceFactory

### SYNOPSIS

Factory class to create validation resource objects.

### DESCRIPTION

The `validationResourceFactory` class is responsible for creating instances of `aprlResourceObj` for validation purposes based on recommendation objects, validation resources, and types not in APRL or ADVISOR.

### PROPERTIES

- **recommendationObject**: The recommendation object.
- **validationResources**: The validation resources.
- **TypesNotInAPRLOrAdvisor**: Resource types that we want to create a recommendation for but do not have a recommendation for.

### CONSTRUCTORS

```powershell
validationResourceFactory([PSObject]$recommendationObject, [hashtable]$validationResources, [PSObject]$TypesNotInAPRLOrAdvisor)
```

### METHODS

```powershell
[object[]] createValidationResourceObjects()
```

Creates and returns an array of `aprlResourceObj` instances for validation purposes based on the recommendation objects, validation resources, and types not in APRL or ADVISOR.

```powershell
static [string] getValidationAction($query)
```

Determines the validation action based on the provided query string.

## specializedResourceFactory

### SYNOPSIS

Factory class to create specialized resource objects.

### DESCRIPTION

The `specializedResourceFactory` class is responsible for creating instances of `aprlResourceObj` for specialized resources based on recommendation objects.

### PROPERTIES

- **specializedResources**: The specialized resources.
- **RecommendationObject**: The recommendation object.

### CONSTRUCTORS

```powershell
specializedResourceFactory([PSObject]$specializedResources, [PSObject]$RecommendationObject)
```

### METHODS

```powershell
[object[]] createSpecializedResourceObjects()
```

Creates and returns an array of `aprlResourceObj` instances for specialized resources based on the recommendation objects.

```powershell
static [string] getValidationAction($query)
```

Determines the validation action based on the provided query string.
