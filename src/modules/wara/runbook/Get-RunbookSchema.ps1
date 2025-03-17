<#
.FUNCTION
    Get-RunbookSchema

.SYNOPSIS
    Retrieves the JSON schema for a runbook.

.DESCRIPTION
    The `Get-RunbookSchema` function returns the JSON schema that defines the structure
    of a Well-Architected Reliability Assessment (WARA) runbook. This schema ensures consistency
    in the configuration and validation of runbook content.

.OUTPUTS
    [string]
    The JSON schema as a string.

.EXAMPLE
    $schema = Get-RunbookSchema

    Retrieves the JSON schema for a runbook, ensuring it adheres to the expected structure.

.NOTES
    Author: Casey Watson
    Date: 2025-02-27
#>
function Get-RunbookSchema {
    @"
{
  "title": "Runbook",
  "description": "A well-architected reliability assessment (WARA) runbook",
  "type": "object",
  "properties": {
    "parameters": {
      "type": "object"
    },
    "variables": {
      "type": "object"
    },
    "selectors": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    },
    "checks": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "additionalProperties": {
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "selector": {
                  "type": "string"
                },
                "parameters": {
                  "type": "object"
                },
                "tags": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              },
              "required": [
                "selector"
              ]
            }
          ]
        }
      }
    }
  },
  "required": [
    "selectors",
    "checks"
  ]
}
"@
}
