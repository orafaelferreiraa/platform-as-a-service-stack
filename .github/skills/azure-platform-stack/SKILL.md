---
name: azure-platform-stack
description: Azure infrastructure specialist for Platform as a Service Stack v3.0.0+. Expert in deterministic naming (MD5), RBAC-first security (uuidv5), feature flag orchestration, and Azure AD authentication. Always consults Microsoft Docs and Terraform provider MCP before ANY implementation to ensure latest best practices and avoid anti-patterns.
---

# Azure Platform Stack Specialist

## Overview

This skill provides expert guidance for Azure infrastructure operations in the **Platform as a Service Stack v3.0.0+** environment. It focuses on deterministic resource provisioning, RBAC-first security, feature flag management, and ensuring compliance with platform-specific patterns (MD5 naming, uuidv5 role assignments, 180s RBAC propagation).

## When to Use This Skill

- Implementing new Azure resources for Platform Stack (Storage Account, SQL Server, Key Vault, Container Apps, etc.)
- Debugging RBAC propagation delays or "permission denied" errors
- Validating deterministic naming patterns (MD5 suffixes)
- Troubleshooting Azure AD authentication (storage_use_azuread)
- Implementing feature flag dependencies (e.g., Container Apps requires Observability)
- Fixing Azure Provider 4.x deprecated attributes
- Optimizing RBAC role assignments with uuidv5()
- Applying Platform Stack security standards (RBAC-first, no shared keys)

## MCP Integration

> **Canonical source**: See agent's MCP Tool Usage Protocol. Always consult Microsoft Docs and Terraform provider MCP before any implementation.

## Critical Platform Stack Standards

### Fixed Platform Configuration

**Non-configurable settings:**
- **Region**: `eastus2` (hardcoded, not configurable)
- **Location Abbreviation**: `eus2`
- **Terraform Version**: ~> 1.14
- **Provider Version**: azurerm ~> 4.64.0, random ~> 3.8.1, time ~> 0.13.1
- **State Backend**: Azure Blob Storage with `use_azuread_auth = true`

### Naming Convention

> See `terraform-platform-instructions.md` — Naming section. Pattern: `{name}-{location_abbr}-{md5_suffix}`, ACR: `cr{name}{region}{md5}`.

### RBAC Security

> See `terraform-platform-instructions.md` — RBAC section. Key rules: `shared_access_key_enabled = false`, `rbac_authorization_enabled = true`, `storage_use_azuread = true`.

### Role Assignments

> See `terraform-platform-instructions.md` for uuidv5 pattern: `name = uuidv5("dns", "${scope}-${principal}-{role}")`. 

### RBAC Propagation

> See `terraform-platform-instructions.md` — 180s `time_sleep` required before secrets/containers after role assignment.

### Feature Flag Dependencies

**Validation at root main.tf (NOT in modules)**:

```hcl
# Container Apps REQUIRES Observability
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability (enable_observability=true)' && exit 1"
  }
}
```

**Feature Flag Table**:

| Flag | Resource | Hard Dependency | Recommended Dependency |
|------|----------|----------------|------------------------|
| `enable_managed_identity` | Managed Identity | - | **Used by all workloads for RBAC** |
| `enable_vnet` | VNet Spoke | - | Used by Storage, SQL, Container Apps |
| `enable_observability` | Log Analytics + App Insights | - | **REQUIRED by Container Apps** |
| `enable_storage` | Storage Account | - | Managed Identity (RBAC), VNet |
| `enable_service_bus` | Service Bus | - | Managed Identity |
| `enable_event_grid` | Event Grid | - | Managed Identity, Service Bus |
| `enable_sql` | SQL Server | - | Managed Identity, VNet |
| `enable_key_vault` | Key Vault | SQL (for password) | Managed Identity |
| `enable_container_registry` | Container Registry | - | Managed Identity (RBAC) | `enable_container_registry = true` |
| `enable_container_apps` | Container Apps | **Observability** | VNet, Container Registry + MI | `enable_container_apps = true` |

### Provider Configuration Standards

```hcl
terraform {
  required_version = "~> 1.14"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64.0"  # MANDATORY: ~> constraint
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"  # For time_sleep resources
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "platform.terraform.tfstate"  # Overridden in init
    use_azuread_auth     = true  # MANDATORY (no access keys)
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true  # CRITICAL for Storage Account without keys
}
```

## Common Implementation Tasks

### 1. Creating Storage Account Module

**MCP workflow:**
```
1. microsoft_docs_search("Azure Storage Account security best practices")
2. microsoft_code_sample_search("azurerm_storage_account", language="terraform")
3. mcp_hashicorp_ter_get_provider_details("hashicorp/azurerm/azurerm_storage_account")
4. read_file("terraform/modules/workloads/storage-account/main.tf") # Reference
```

### 2. Creating Container Registry Module (External)

**Source**: External module from `tfmodules-as-a-service-stack`

**MCP workflow:**
```
1. microsoft_docs_search("Azure Container Registry security best practices")
2. microsoft_code_sample_search("azurerm_container_registry", language="terraform")
3. mcp_hashicorp_ter_get_provider_details("hashicorp/azurerm/azurerm_container_registry")
4. read_file("terraform/modules/workloads/container-apps/main.tf") # Reference for MI integration
```

**Module source:**
```hcl
module "container_registry" {
  source = "git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry?ref=1.0.3"
  count  = var.enable_container_registry ? 1 : 0

  name                = module.naming.container_registry  # "cr{name}{md5}" e.g. "crmyplatformeus2abc1"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.container_registry_sku  # "Basic" | "Standard" | "Premium"
}
```

**Feature flags:**
```hcl
variable "enable_container_registry" {
  description = "Enable Azure Container Registry"
  type        = bool
  # No default — value comes from pipeline workflow_dispatch
}

variable "container_registry_sku" {
  description = "SKU for Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "container_registry_sku must be Basic, Standard, or Premium."
  }
}
```

**Managed Identity RBAC (auto-assigned):**
```hcl
# AcrPush - allows MI to push images
resource "azurerm_role_assignment" "mi_acr_push" {
  count                = var.enable_container_registry && var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${module.container_registry[0].id}-${module.managed_identity[0].principal_id}-acr-push")
  scope                = module.container_registry[0].id
  role_definition_name = "AcrPush"
  principal_id         = module.managed_identity[0].principal_id
}

# AcrPull - allows MI to pull images
resource "azurerm_role_assignment" "mi_acr_pull" {
  count                = var.enable_container_registry && var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${module.container_registry[0].id}-${module.managed_identity[0].principal_id}-acr-pull")
  scope                = module.container_registry[0].id
  role_definition_name = "AcrPull"
  principal_id         = module.managed_identity[0].principal_id
}
```

**Container Apps zero-config integration:**
```hcl
# MI is pre-attached to Container Apps Environment
# ACR login_server is passed through automatically
module "container_apps" {
  source = "./modules/workloads/container-apps"
  count  = var.enable_container_apps ? 1 : 0

  # ... other config ...
  managed_identity_id   = var.enable_managed_identity ? module.managed_identity[0].id : null
  container_registry_url = var.enable_container_registry ? module.container_registry[0].login_server : null
}
```

**Outputs (individual, no resource IDs):**
The root `outputs.tf` exposes only safe values: `container_apps_environment_name`, `container_apps_environment_default_domain`, `container_apps_environment_static_ip`, `container_registry_name`, `container_registry_login_server`. Resource IDs were removed because they expose the subscription ID.
```

**Key points:**
- External module: pinned at `ref=1.0.3` from `tfmodules-as-a-service-stack`
- Naming: `cr{name}{region}{md5}` (no hyphens — Azure ACR doesn't allow them)
- RBAC: AcrPush + AcrPull auto-assigned to Managed Identity via uuidv5
- Container Apps: MI pre-attached to Environment + ACR `login_server` passed through (zero-config pull)
- SKU validation: only `Basic`, `Standard`, or `Premium` accepted

### Multi-Subscription Provider Architecture

```terraform
# providers.tf
provider "azurerm" {
  alias           = "stefanininam"
  subscription_id = var.stefanininam_subscription_id
  tenant_id       = var.stefanininam_tenant_id
  client_id       = var.stefanininam_client_id
  client_secret   = var.stefanininam_client_secret

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azurerm" {
  alias           = "devops"
  subscription_id = var.devops_subscription_id
  tenant_id       = var.devops_tenant_id
  client_id       = var.devops_client_id
  client_secret   = var.devops_client_secret
  features {}
}

provider "azurerm" {
  alias           = "sophie"
  subscription_id = var.sophie_subscription_id
  tenant_id       = var.sophie_tenant_id
  client_id       = var.sophie_client_id
  client_secret   = var.sophie_client_secret
  features {}
}
```

**Subscription mapping:**
- `stefanininam` - Primary workload subscription (AKS, applications)
- `devops` - Terraform state storage, automation infrastructure
- `sophie` - Sophie tenant resources
- `woopi` - WoopiAI tenant resources
- Additional client tenants as needed

**Resource usage:**
```terraform
resource "azurerm_resource_group" "main" {
  provider = azurerm.stefanininam  # EXPLICIT provider reference
  name     = "na-rg-prod"
  location = "East US"
}
```

### Naming Conventions

**Standard pattern:** `<tenant>-<resource>-<environment>`

**Tenant prefixes:**
- `na` - North America (primary)
- `sophie` - Sophie tenant
- `woopi` - WoopiAI platform
- `dex` - Data Exchange
- `emea` - Europe/Middle East/Africa
- `latam` - Latin America

**Resource examples:**
```terraform
# AKS clusters
"na-aks-prod"
"sophie-aks-dev"
"woopi-aks-prod"

# Resource groups
"na-rg-network"
"sophie-rg-data"
"woopi-rg-storage"

# Storage accounts (lowercase, no hyphens due to Azure limits)
"stapplicationsautomation"
"stsophiedataprod"
"stwoopidatadev"

# Key Vaults
"na-kv-secrets-prod"
"sophie-kv-dev"
"woopi-kv-prod"

# AKS node pools
"system" (system pool)
"user" (user workloads)
"gpu" (GPU workloads)
```

### Provider Version Management

> See `terraform-platform-instructions.md` — Provider versions. Use `~> 4.64.0` for azurerm, `~> 1.14` for Terraform. Always pin with `~>` constraint and check latest via MCP before generating code.

### Security Standards

**Production requirements:**
- Private endpoints for all PaaS services (Storage, Key Vault, SQL, ACR)
- Managed Identity instead of Service Principal
- Azure AD RBAC enabled on AKS
- Network security groups (NSGs) on all subnets
- Private DNS zones for private endpoints
- Customer-Managed Keys (CMK) for encryption at rest
- Azure Policy for governance

**Development/QA:**
- Can use public endpoints with IP restrictions
- Still use Managed Identity where possible
- Network security still required

### 2. Creating AKS Cluster

**MCP workflow:**
1. Search: "AKS private cluster terraform best practices"
2. Get samples: "AKS private cluster" with language="terraform"
3. Get provider: azurerm kubernetes_cluster resource details
4. Review: aks-terraform-template/main.tf

**Implementation checklist:**
```terraform
resource "azurerm_kubernetes_cluster" "main" {
  provider            = azurerm.stefanininam  # ✓ Explicit provider
  name                = "${var.tenant}-aks-${var.environment}"  # ✓ Naming convention
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.tenant}-aks-${var.environment}"

  # ✓ Private cluster for production
  private_cluster_enabled = var.environment == "prod"

  # ✓ Azure CNI networking
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
    load_balancer_sku = "standard"
  }

  # ✓ Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # ✓ OIDC and Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # ✓ Azure AD RBAC
  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_ids
  }

  # ✓ System node pool
  default_node_pool {
    name                  = "system"
    node_count            = 3
    vm_size               = "Standard_D4s_v3"
    vnet_subnet_id        = azurerm_subnet.aks.id
    enable_auto_scaling   = true
    min_count             = 3
    max_count             = 10
    enable_node_public_ip = false  # Private nodes
  }

  # ✓ Tags
  tags = local.common_tags
}
```

### 3. Creating Storage Account

**MCP workflow:**
1. Search: "Azure storage account security best practices"
2. Get samples: "storage account terraform" with language="terraform"
3. Get provider: azurerm_storage_account resource details

**Implementation:**
```terraform
resource "azurerm_storage_account" "data" {
  provider                 = azurerm.stefanininam
  name                     = "st${var.tenant}data${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"

  # Security settings
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Network rules
  network_rules {
    default_action             = "Deny"
    ip_rules                   = var.allowed_ips
    virtual_network_subnet_ids = [azurerm_subnet.data.id]
    bypass                     = ["AzureServices"]
  }

  # Blob properties
  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

# Private endpoint for production
resource "azurerm_private_endpoint" "storage" {
  count               = var.environment == "prod" ? 1 : 0
  provider            = azurerm.stefanininam
  name                = "${azurerm_storage_account.data.name}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${azurerm_storage_account.data.name}-psc"
    private_connection_resource_id = azurerm_storage_account.data.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
```

### 4. Creating Key Vault

**MCP workflow:**
1. Search: "Azure Key Vault terraform security"
2. Get samples: "key vault" with language="terraform"
3. Get provider: azurerm_key_vault resource details

**Implementation:**
```terraform
resource "azurerm_key_vault" "main" {
  provider                   = azurerm.stefanininam
  name                       = "${var.tenant}-kv-${var.environment}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = var.environment == "prod"

  # Network ACLs
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.allowed_ips
    virtual_network_subnet_ids = [azurerm_subnet.aks.id]
  }

  # RBAC (recommended over access policies)
  enable_rbac_authorization = true

  tags = local.common_tags
}
```

## Debugging Strategies

### Authentication Issues

**Symptoms:**
- "Error: building account: could not acquire access token"
- "Error: Authorization failed"
- "Error: insufficient privileges"

**MCP workflow:**
1. Search: "Azure authentication troubleshooting terraform"
2. Review Microsoft docs for service principal setup

**Debugging steps:**
```powershell
# Verify environment variables
echo $env:ARM_SUBSCRIPTION_ID
echo $env:ARM_TENANT_ID
echo $env:ARM_CLIENT_ID
# ARM_CLIENT_SECRET should be set but not echoed

# Verify service principal exists
az ad sp show --id $env:ARM_CLIENT_ID

# Test authentication
az login --service-principal `
  --username $env:ARM_CLIENT_ID `
  --password $env:ARM_CLIENT_SECRET `
  --tenant $env:ARM_TENANT_ID

# Check subscription access
az account show
az account list --all

# Check RBAC role assignments
az role assignment list --assignee $env:ARM_CLIENT_ID
```

**Common fixes:**
- Verify service principal has Contributor role on subscription
- Check service principal hasn't expired
- Validate client secret is current
- Ensure correct tenant ID and subscription ID

### Networking Issues

**Symptoms:**
- "Error: timeout while waiting for state"
- "Error: unable to connect to backend"
- Private endpoint connection failures

**MCP workflow:**
1. Search: "Azure private endpoint troubleshooting"
2. Review NSG and route table configurations

**Debugging steps:**
```powershell
# Check NSG rules
az network nsg show --resource-group <rg> --name <nsg-name>

# Check route table
az network route-table show --resource-group <rg> --name <rt-name>

# Check private DNS zone
az network private-dns zone show --resource-group <rg> --name <zone-name>

# Test DNS resolution
nslookup <resource>.privatelink.blob.core.windows.net

# Check service endpoint
az network vnet subnet show --resource-group <rg> --vnet-name <vnet> --name <subnet>
```

### State Lock Issues

**Symptoms:**
- "Error: Error locking state"
- "Error: state blob is already locked"

**MCP workflow:**
1. Search: "Terraform Azure blob storage state lock"

**Resolution:**
```powershell
# Check blob lease status
az storage blob show `
  --account-name storagepaas `
  --container-name tfstate `
  --name <tenant>-<environment>.tfstate `
  --query properties.lease

# Break lease if stuck (CAUTION: verify no one is running terraform)
az storage blob lease break `
  --blob-name <tenant>-<environment>.tfstate `
  --container-name tfstate `
  --account-name storagepaas
```

### Resource Already Exists

**Symptoms:**
- "Error: A resource with the ID already exists"

**MCP workflow:**
1. Check if resource exists in Azure Portal
2. Decide: import or remove

**Option 1: Import existing resource:**
```bash
# Get resource ID from Azure
az resource show --resource-group <rg> --name <name> --resource-type <type>

# Import into Terraform state
terraform import azurerm_resource_group.main /subscriptions/<sub-id>/resourceGroups/<rg-name>

# Verify
terraform plan  # Should show no changes
```

**Option 2: Remove from state:**
```bash
terraform state rm azurerm_resource_group.main
```

## Multi-Tenant Deployment Workflow

When deploying to a new tenant:

1. **Create provider alias** in `providers.tf`
2. **Add variables** in `variables.tf`:
   ```terraform
   variable "newtenant_subscription_id" {
     description = "New tenant subscription ID"
     type        = string
     sensitive   = true
   }
   # ... tenant_id, client_id, client_secret
   ```

3. **Configure GitHub secrets:**
   - `NEWTENANT_SUBSCRIPTION_ID`
   - `NEWTENANT_TENANT_ID`
   - `NEWTENANT_CLIENT_ID`
   - `NEWTENANT_CLIENT_SECRET`

4. **Create config structure:**
   ```
   cluster-config/specific/newtenant/
   ├── dev.tfvars
   ├── qa.tfvars
   └── prod.tfvars
   ```

5. **Update backend state key:**
   ```terraform
   key = "<project>-newtenant-<environment>.tfstate"
   ```

6. **Test deployment:**
   ```bash
   terraform init -backend-config="key=<project>-newtenant-dev.tfstate"
   terraform plan -var-file="cluster-config/specific/newtenant/dev.tfvars"
   ```


