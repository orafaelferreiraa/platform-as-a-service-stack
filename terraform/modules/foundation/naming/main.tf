# Random suffix for globally unique resource names
# Uses keepers to ensure the suffix only changes when the project name changes
resource "random_string" "suffix" {
  length  = 4
  lower   = true
  upper   = false
  numeric = true
  special = false

  keepers = {
    # Suffix only regenerates if the project name changes
    name = var.name
  }
}

locals {
  name   = lower(var.name)
  suffix = random_string.suffix.result

  # Location abbreviations
  location_abbreviations = {
    "eastus"         = "eus"
    "eastus2"        = "eus2"
    "westus"         = "wus"
    "westus2"        = "wus2"
    "centralus"      = "cus"
    "northcentralus" = "ncus"
    "southcentralus" = "scus"
    "westcentralus"  = "wcus"
    "westeurope"     = "weu"
    "northeurope"    = "neu"
    "brazilsouth"    = "brs"
    "uksouth"        = "uks"
    "ukwest"         = "ukw"
  }

  location_abbr = lookup(local.location_abbreviations, var.location, substr(var.location, 0, 3))

  # Base naming patterns
  # Resources that need global uniqueness include the suffix
  base_name_pattern        = "${local.name}-${local.location_abbr}"
  base_name_pattern_unique = "${local.name}-${local.location_abbr}-${local.suffix}"
  base_name_no_separator   = "${local.name}${local.location_abbr}"
  base_name_unique_compact = "${local.name}${local.location_abbr}${local.suffix}"
}
