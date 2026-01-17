# Foundation Module: Naming Convention
# Generates standardized resource names following Azure naming conventions

locals {
  name          = lower(var.name)
  location_abbr = lookup(local.location_abbreviations, var.location, substr(var.location, 0, 3))

  location_abbreviations = {
    "eastus"             = "eus"
    "eastus2"            = "eus2"
    "westus"             = "wus"
    "westus2"            = "wus2"
    "westus3"            = "wus3"
    "centralus"          = "cus"
    "northcentralus"     = "ncus"
    "southcentralus"     = "scus"
    "westcentralus"      = "wcus"
    "canadacentral"      = "cac"
    "canadaeast"         = "cae"
    "brazilsouth"        = "brs"
    "northeurope"        = "neu"
    "westeurope"         = "weu"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "germanywestcentral" = "gwc"
    "switzerlandnorth"   = "szn"
    "norwayeast"         = "noe"
    "swedencentral"      = "sec"
    "australiaeast"      = "aue"
    "australiasoutheast" = "ause"
    "southeastasia"      = "sea"
    "eastasia"           = "ea"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
    "koreacentral"       = "krc"
    "koreasouth"         = "krs"
    "centralindia"       = "cin"
    "southindia"         = "sin"
    "westindia"          = "win"
    "uaenorth"           = "uan"
    "uaecentral"         = "uac"
    "southafricanorth"   = "san"
  }

  # Base name pattern for resources
  base_name_pattern = "${local.name}-${local.location_abbr}"

  # Standard tags
  default_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Platform  = "PaaS"
    Name      = var.name
    Location  = var.location
  })
}
