# =============================================================================
# Backend Configuration - Azure Storage
# =============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
  }
}
