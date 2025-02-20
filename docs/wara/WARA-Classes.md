# WARA Classes

## aprlResourceTypeObj

### SYNOPSIS

Represents a resource type within APRL.

### DESCRIPTION

The `aprlResourceTypeObj` class encapsulates the details of a resource type in APRL, including the number of resources, availability in APRL/ADVISOR, assessment owner, status, and notes. Additionally, this class helps track whether certain resource types are in APRL or Advisor, making it easier to identify coverage gaps.

### PROPERTIES

- **Resource Type**: The type of the resource
- **Number Of Resources**: The number of resources of this type
- **Available in APRL/ADVISOR?**: Indicates whether the resource type is available in APRL or ADVISOR
- **Assessment Owner**: The owner of the assessment
- **Status**: The status of the resource type
- **Notes**: Additional notes about the resource type

## resourceTypeFactory

### SYNOPSIS

Factory class to create resource type objects.

### DESCRIPTION

The `resourceTypeFactory` class is responsible for creating instances of `aprlResourceTypeObj` based on impacted resources and types not in APRL or ADVISOR. Additionally, the factory aggregates impacted resource types and ensures resources that aren't in APRL or Advisor are still recorded for assessment.

### CONSTRUCTORS

```powershell
resourceTypeFactory([PSObject]$impactedResourceObj, [PSObject]$TypesNotInAPRLOrAdvisor)
```

Initializes a new instance of the `resourceTypeFactory` class.

### SPECIALIZED RESOURCE METHODS

```powershell
[object[]] createResourceTypeObjects()
```

Creates and returns an array of `aprlResourceTypeObj` instances.

## aprlResourceObj

### SYNOPSIS

Represents a single APRL resource.

### DESCRIPTION

The `aprlResourceObj` class encapsulates the details of an APRL resource, including validation action, recommendation ID, name, ID, type, location, subscription ID, resource group, parameters, check name, and selector. Additionally, this class simplifies referencing all key resource details in one place, which is crucial for building and filtering recommendations.

### PROPERTIES

- **validationAction**: The validation action for the resource
- **recommendationId**: The recommendation ID for the resource
- **name**: The name of the resource
- **id**: The ID of the resource
- **type**: The type of the resource
- **location**: The location of the resource
- **subscriptionId**: The subscription ID of the resource
- **resourceGroup**: The resource group of the resource
- **param1-5**: Additional parameters
- **checkName**: The check name for the resource
- **selector**: The selector for the resource

## impactedResourceFactory

### SYNOPSIS

Factory class to create impacted resource objects.

### DESCRIPTION

The `impactedResourceFactory` class is responsible for creating instances of `aprlResourceObj` based on impacted resources, all resources, and recommendation objects. Additionally, it allows collecting all resource insights (like impacted or in-scope resources) into aprlResourceObj objects, ensuring a uniform format.

### IMPACTED RESOURCE CONSTRUCTORS

```powershell
impactedResourceFactory([PSObject]$impactedResources, [hashtable]$allResources, [hashtable]$RecommendationObject)
```

### METHODS

```powershell
[object[]] createImpactedResourceObjects()
```

Creates and returns an array of `aprlResourceObj` instances.

## validationResourceFactory

### SYNOPSIS

Factory class to create validation resource objects.

### DESCRIPTION

The `validationResourceFactory` class is responsible for creating instances of `aprlResourceObj` for validation purposes based on recommendation objects, validation resources, and types not in APRL or ADVISOR. Additionally, it handles resources that do not receive direct recommendations, ensuring they still undergo fundamental validations.

### VALIDATION RESOURCE CONSTRUCTORS

```powershell
validationResourceFactory([PSObject]$recommendationObject, [hashtable]$validationResources, [PSObject]$TypesNotInAPRLOrAdvisor)
```

### METHODS

```powershell
[object[]] createValidationResourceObjects()
[string] getValidationAction($query)
```

## specializedResourceFactory

### SYNOPSIS

Factory class to create specialized resource objects.

### DESCRIPTION

The `specializedResourceFactory` class is responsible for creating instances of `aprlResourceObj` for specialized resources based on recommendation objects. Additionally, the factory decides how to handle specialized workloads (e.g., SAP, AVD) by generating resource objects that meet specific requirements.

### SPECIALIZED RESOURCE CONSTRUCTORS

```powershell
specializedResourceFactory([PSObject]$specializedResources, [PSObject]$RecommendationObject)
```

### METHODS

```powershell
[object[]] createSpecializedResourceObjects()
[string] getValidationAction($query)
```
