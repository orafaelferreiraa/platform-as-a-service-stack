locals {
  name = lower(var.name)

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

  # Base naming pattern
  base_name_pattern      = "${local.name}-${local.location_abbr}"
  base_name_no_separator = "${local.name}${local.location_abbr}"
}
