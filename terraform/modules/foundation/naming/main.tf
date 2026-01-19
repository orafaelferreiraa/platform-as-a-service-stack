# Deterministic suffix for globally unique resource names
# Uses MD5 hash of name to generate consistent suffix - same name always produces same suffix
locals {
  name = lower(var.name)
  # Generate a 4-character suffix from MD5 hash of the name
  # This is deterministic: same name = same suffix, always
  suffix = substr(md5(var.name), 0, 4)

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
