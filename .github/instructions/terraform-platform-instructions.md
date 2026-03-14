---
name: "Terraform Code Standards - Platform as a Service Stack"
description: "Terraform patterns, module structure, and deterministic naming for Platform Stack"
applyTo: "**/*.{tf,tfvars}"
---

# Terraform Code Standards - Platform as a Service Stack

## MCP Integration - MANDATORY Before Any Terraform Work
**ALWAYS execute these MCP queries BEFORE generating/modifying Terraform code**:

### Provider/Module Version Lookup
```bash
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "azurerm")
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "random")
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "time")
```

### Resource Documentation
```bash
mcp_hashicorp_ter_search_providers(query: "azurerm storage_account")
mcp_hashicorp_ter_get_provider_details(
  namespace: "hashicorp",
  name: "azurerm",
  type: "azurerm_storage_account"
)
```

### Module Discovery
```bash
mcp_hashicorp_ter_search_modules(query: "azure resource group")
mcp_hashicorp_ter_get_module_details(module_id: "Azure/naming/azurerm/0.4.1")
```

**Never guess resource arguments** - always consult Terraform registry via MCP tools.

---

## Platform Stack Terraform Architecture

### Fixed Configuration
- **Terraform Version**: ~> 1.14
- **Provider Versions**: 
  - azurerm: ~> 4.64.0
  - random: ~> 3.8.1
  - time: ~> 0.13.1
- **Region**: eastus2 (hardcoded)
- **State Backend**: Azure Blob Storage with Azure AD authentication

### Project Structure
```
terraform/
├── backend.tf              # State backend configuration
├── main.tf                 # Root orchestration (ONLY place for module calls)
├── providers.tf            # Provider configurations
├── variables.tf            # Feature flags + global inputs
├── outputs.tf              # Consolidated outputs
├── test.tfvars            # Example configuration
└── modules/
    ├── foundation/
    │   ├── naming/         # MD5-based deterministic naming
    │   └── resource-group/ # Base resource group
    ├── networking/
    │   └── vnet-spoke/     # VNet with /27 delegated subnet
    ├── security/
    │   ├── managed-identity/ # User-assigned identity
    │   └── key-vault/      # RBAC-enabled vault
    └── workloads/
        ├── observability/  # Log Analytics + App Insights
        ├── storage-account/ # RBAC-only storage
        ├── service-bus/    # Premium namespace
        ├── event-grid/     # Domain with subscriptions
        ├── sql/            # SQL Server + Database
        └── container-apps/ # Container Apps Environment

# External Modules (pinned git refs — NOT in modules/ tree)
# └── Container Registry (ACR)
#     Source: git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry?ref=1.0.3
```

---

## Terraform State Management (CRITICAL)

### Azure Blob Storage Backend
**ALL Platform Stack deployments use remote state** - NEVER local state:

```terraform
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "platform.terraform.tfstate"
    use_azuread_auth     = true  # MANDATORY (no shared keys)
  }
}
```

### State Initialization
```bash
cd terraform
terraform init \
  -backend-config="resource_group_name=rg-paas" \
  -backend-config="storage_account_name=storagepaas" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=myplatform.terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
```

### State Lock Behavior
- **Locked during**: `terraform plan`, `terraform apply`, `terraform refresh`
- **Lock location**: Azure Blob Storage blob lease
- **If stuck**: Manually break lease in Azure Portal → Storage Account → Containers → tfstate → Blob properties

### State File Naming Convention
`<platform-name>.terraform.tfstate`

**Examples**:
- `myapp.terraform.tfstate`
- `production-platform.terraform.tfstate`

---

## Deterministic Naming Convention (MD5-Based)

### Core Principle
**NEVER use `random_string` or `random_uuid`** - causes destroy/recreate cycles

### Implementation Pattern
```terraform
# modules/foundation/naming/main.tf
locals {
  name          = lower(var.name)
  location_abbr = var.location == "eastus2" ? "eus2" : (
                  var.location == "westus2" ? "wus2" : "eus2"
                  )
  suffix        = substr(md5(local.name), 0, 4)
  
  # Globally unique resources (Azure enforces uniqueness)
  storage_account = "st${replace(local.name, "-", "")}${local.location_abbr}${local.suffix}"
  key_vault       = "kv-${local.name}-${local.location_abbr}-${local.suffix}"
  sql_server      = "sql-${local.name}-${local.location_abbr}-${local.suffix}"
  app_insights    = "appi-${local.name}-${local.location_abbr}-${local.suffix}"
  
  # Regional resources
  resource_group         = "rg-${local.name}-${local.location_abbr}"
  managed_identity       = "id-${local.name}-${local.location_abbr}"
  vnet                   = "vnet-${local.name}-${local.location_abbr}"
  log_analytics          = "log-${local.name}-${local.location_abbr}"
  service_bus_namespace  = "sb-${local.name}-${local.location_abbr}"
  event_grid_domain      = "evgd-${local.name}-${local.location_abbr}"
  container_app_env      = "cae-${local.name}-${local.location_abbr}"
  
  # Globally unique (alphanumeric only — no hyphens, no dots)
  container_registry     = "cr${local.name}${local.md5_suffix}"
}
```

**Why MD5?** Same input (`var.name`) = same suffix always = idempotent Terraform

### Validation
```bash
# Check for forbidden patterns
grep -r "random_string\|random_uuid" terraform/modules/
# Expected: Empty (no results)
```

---

## Module Development Standards

### Module Structure (MANDATORY)
Every module in `terraform/modules/{domain}/{resource}/` MUST have:

```
module-name/
├── main.tf         # Resource definitions + RBAC + network rules
├── variables.tf    # Input parameters with descriptions
├── outputs.tf      # Return values for cross-module use
└── README.md       # Auto-generated documentation (optional)
```

### Module Variables Pattern
```terraform
# variables.tf
variable "name" {
  description = "Platform name (lowercase alphanumeric only, used for MD5 suffix)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "Name must be lowercase alphanumeric only (no hyphens, spaces, or special chars)"
  }
}

variable "location" {
  description = "Azure region (fixed to eastus2 in root variables)"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Resource tags (merged with common tags)"
  type        = map(string)
  default     = {}
}

variable "managed_identity_principal_id" {
  description = "Principal ID of Managed Identity for RBAC assignments (optional)"
  type        = string
  default     = null
}
```

### Module Outputs Pattern
**Export ONLY names, FQDNs, URIs, principals - NEVER resource IDs (contain subscription ID) or secret values**:

```terraform
# outputs.tf — root module exposes only safe values
output "name" {
  description = "Resource name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary Blob service endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

# ❌ WRONG - Never export resource IDs (expose subscription ID)
# output "id" {
#   value = azurerm_storage_account.main.id
# }

# ❌ WRONG - Never export secret values
# output "primary_access_key" {
#   value     = azurerm_storage_account.main.primary_access_key
#   sensitive = true
# }

# ✅ CORRECT - Export secret URI instead
output "secret_uri" {
  description = "Key Vault secret URI containing connection string"
  value       = azurerm_key_vault_secret.connection_string.versionless_id
}
```

---

## Root-Level Orchestration (main.tf)

### Single Orchestration Point
**CRITICAL**: ALL module-to-module dependencies orchestrated in `terraform/main.tf`

**DO NOT** create inter-module dependencies within modules themselves.

### Module Call Pattern
```terraform
# terraform/main.tf

# Layer 1: Foundation (no dependencies)
module "naming" {
  source   = "./modules/foundation/naming"
  name     = var.name
  location = var.location
}

module "resource_group" {
  source   = "./modules/foundation/resource-group"
  name     = module.naming.resource_group
  location = var.location
  tags     = var.tags
}

module "managed_identity" {
  count = var.enable_managed_identity ? 1 : 0
  
  source              = "./modules/security/managed-identity"
  name                = module.naming.managed_identity
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

# Layer 2: Workloads (optional dependencies)
module "storage" {
  count = var.enable_storage ? 1 : 0
  
  source                         = "./modules/workloads/storage-account"
  name                           = module.naming.storage_account
  location                       = var.location
  resource_group_name            = module.resource_group.name
  managed_identity_principal_id  = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  vnet_subnet_ids                = var.enable_vnet ? [module.vnet_spoke[0].default_subnet_id] : []
  tags                           = var.tags
}

# Layer 3: Container Registry (EXTERNAL module — pinned git ref)
module "container_registry" {
  count = var.enable_container_registry ? 1 : 0
  
  source                        = "git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry?ref=1.0.3"
  name                          = module.naming.container_registry
  location                      = var.location
  resource_group_name           = module.resource_group.name
  sku                           = var.container_registry_sku
  managed_identity_principal_id = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  tags                          = var.tags
}

# Layer 4: Compute (hard requirements)
module "container_apps" {
  count = var.enable_container_apps ? 1 : 0
  
  source                              = "./modules/workloads/container-apps"
  name                                = module.naming.container_app_env
  location                            = var.location
  resource_group_name                 = module.resource_group.name
  log_analytics_workspace_id          = module.observability[0].log_analytics_workspace_id  # REQUIRED
  infrastructure_subnet_id            = var.enable_vnet ? module.vnet_spoke[0].container_apps_subnet_id : null
  managed_identity_id                 = var.enable_managed_identity ? module.managed_identity[0].id : null
  container_registry_login_server     = var.enable_container_registry ? module.container_registry[0].login_server : null
  tags                                = var.tags
  
  depends_on = [module.observability]
}
```

> **Note**: The root `outputs.tf` exposes only safe values (names, FQDNs, URIs, domains, IPs). Resource IDs are NOT exported because they contain the subscription ID. The `container_app_ready_config` composite output was removed for the same reason.

---

## Feature Flag Pattern

### Feature Flag Variables
```terraform
# terraform/variables.tf

# MANDATORY input
variable "name" {
  description = "Platform name (lowercase alphanumeric, used for MD5 suffix)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "Name must be lowercase alphanumeric only"
  }
}

# Feature flags (no defaults — values come from pipeline)
variable "enable_managed_identity" {
  description = "Enable User-Assigned Managed Identity (RECOMMENDED for RBAC)"
  type        = bool
}

variable "enable_vnet" {
  description = "Enable VNet Spoke with default and delegated subnets"
  type        = bool
}

variable "enable_observability" {
  description = "Enable Log Analytics + Application Insights (REQUIRED for Container Apps)"
  type        = bool
}

variable "enable_storage" {
  description = "Enable Storage Account with RBAC authentication"
  type        = bool
}

variable "enable_container_apps" {
  description = "Enable Container Apps Environment (REQUIRES enable_observability=true)"
  type        = bool
}

variable "enable_container_registry" {
  description = "Enable Azure Container Registry (ACR) for container image storage"
  type        = bool
}

variable "container_registry_sku" {
  description = "SKU for Container Registry (Basic, Standard, or Premium)"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "container_registry_sku must be Basic, Standard, or Premium"
  }
}
```

### Feature Flag Validation
```terraform
# terraform/main.tf

# Validate hard dependencies
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability (enable_observability=true)' && exit 1"
  }
}
```

---

## Count Conditions (Boolean ONLY)

### CORRECT Pattern
```terraform
# ✅ CORRECT - Boolean flag deterministic
count = var.enable_observability ? 1 : 0

# ✅ CORRECT - Combined boolean flags
count = var.enable_storage && var.enable_managed_identity ? 1 : 0
```

### WRONG Patterns (NEVER DO THIS)
```terraform
# ❌ WRONG - Null checks cause "depends on resource attributes" error
count = var.log_analytics_workspace_id != null ? 1 : 0

# ❌ WRONG - Empty string checks
count = var.some_id != "" ? 1 : 0

# ❌ WRONG - Using string variables directly
count = var.workspace_id ? 1 : 0
```

**Why?** Terraform cannot evaluate resource attributes during plan phase.

### Validation
```bash
# Check for forbidden patterns
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/
# Expected: Empty (no results)
```

---

## RBAC Role Assignments (Deterministic)

### MANDATORY Pattern with uuidv5()
**ALWAYS use deterministic role assignment names** - prevents destroy/recreate cycles:

```terraform
resource "azurerm_role_assignment" "mi_storage_blob_contributor" {
  name                 = uuidv5("dns", "${azurerm_storage_account.main.id}-${var.managed_identity_principal_id}-blob-contributor")
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_principal_id
}

resource "azurerm_role_assignment" "current_admin_kv" {
  name                 = uuidv5("dns", "${azurerm_key_vault.main.id}-${data.azurerm_client_config.current.object_id}-admin")
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Container Registry — AcrPush + AcrPull auto-assigned to Managed Identity
resource "azurerm_role_assignment" "mi_acr_push" {
  name                 = uuidv5("dns", "${azurerm_container_registry.main.id}-${var.managed_identity_principal_id}-acrpush")
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = var.managed_identity_principal_id
}

resource "azurerm_role_assignment" "mi_acr_pull" {
  name                 = uuidv5("dns", "${azurerm_container_registry.main.id}-${var.managed_identity_principal_id}-acrpull")
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.managed_identity_principal_id
}
```

**Why `uuidv5()`?**
- **Deterministic**: Same inputs = same UUID always
- **Idempotent**: No destroy/recreate cycles
- **Azure Behavior**: Without `name`, Azure generates random UUID on every apply

### RBAC Propagation Delay (time_sleep)
**MANDATORY**: Add 180s delay between role assignment and dependent resources:

```terraform
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin_kv]
  create_duration = "180s"
  
  triggers = {
    role_assignment_id = azurerm_role_assignment.current_admin_kv.id
  }
}

# Secrets/containers created AFTER RBAC propagation
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = random_password.sql.result
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [time_sleep.wait_for_rbac]
}

resource "azurerm_storage_container" "data" {
  name               = "data"
  storage_account_id = azurerm_storage_account.main.id
  
  depends_on = [time_sleep.wait_for_rbac]
}
```

**Common Error**: "does not have secrets get permission on key vault" → Missing `time_sleep`

### Validation
```bash
# All role assignments MUST have 'name' attribute
grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="
# Expected: Empty (no results)
```

---

## Provider Version Constraints

### Version Pinning Format
**ALWAYS use `~>` for controlled updates**:

```terraform
# terraform/providers.tf or versions.tf
terraform {
  required_version = "~> 1.14"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.64.0"  # Major.Minor locked, patch flexible
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"
    }
  }
}
```

**Before updating versions**:
```bash
# Use MCP to check latest versions
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "azurerm")
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "random")
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "time")
```

**Current Platform Stack Standards**:
- **azurerm**: ~> 4.57.0
- **random**: ~> 3.8.0
- **time**: ~> 0.13.0

### External Module Version Pinning
**ALWAYS pin external modules to a specific git ref** — never use branch names or `HEAD`:

```terraform
# ✅ CORRECT - Pinned to specific tag
source = "git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry?ref=1.0.3"

# ❌ WRONG - Floating branch (non-deterministic)
source = "git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry?ref=main"

# ❌ WRONG - No ref at all
source = "git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry"
```

**Why?** External modules without pinned refs break reproducibility and can cause unexpected plan diffs.

---

## Variable Definitions Best Practices

### Type Constraints (Always Specify)
```terraform
variable "name" {
  description = "Platform name (lowercase alphanumeric)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "Name must be lowercase alphanumeric only"
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "vnet_subnet_ids" {
  description = "List of subnet IDs for network rules"
  type        = list(string)
  default     = []
  
  validation {
    condition     = alltrue([for id in var.vnet_subnet_ids : can(regex("^/subscriptions/", id))])
    error_message = "All subnet IDs must be valid Azure resource IDs"
  }
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for resource"
  type        = bool
  default     = false
}
```

### Sensitive Variables
**Mark credentials and secrets as sensitive**:

```terraform
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure service principal secret"
  type        = string
  sensitive   = true
}

# ❌ WRONG - Never expose secrets in outputs
# output "password" {
#   value     = random_password.sql.result
#   sensitive = true
# }

# ✅ CORRECT - Export secret URI instead
output "password_secret_uri" {
  description = "Key Vault secret URI containing password"
  value       = azurerm_key_vault_secret.password.versionless_id
}
```

---

## Lifecycle Management

### Prevent Destroy on Critical Resources
```terraform
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.location
  tags     = var.tags
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "main" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "main" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_server" "main" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true
  }
}
```

### Ignore External Changes
```terraform
resource "azurerm_container_app_environment" "main" {
  # ... configuration ...
  
  lifecycle {
    ignore_changes = [workload_profile]  # Kubernetes modifies externally
  }
}

resource "azurerm_resource_group" "main" {
  # ... configuration ...
  
  lifecycle {
    ignore_changes = [tags["CreatedDate"]]  # Timestamp changes on every apply
  }
}
```

---

## Common Terraform Patterns

### Data Sources
```terraform
# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Existing resource lookup
data "azurerm_resource_group" "existing" {
  name = "existing-rg-name"
}

# Use in resources
resource "azurerm_key_vault" "main" {
  tenant_id = data.azurerm_client_config.current.tenant_id
  # ...
}
```

### Conditional Resources
```terraform
# Create resource only if flag enabled
resource "azurerm_storage_account" "main" {
  count = var.enable_storage ? 1 : 0
  # ...
}

# Reference with [0] when using count
output "storage_id" {
  value = var.enable_storage ? azurerm_storage_account.main[0].id : null
}
```

### Dynamic Blocks
```terraform
# Network rules only if subnets provided
resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id = azurerm_storage_account.main.id
  default_action     = length(var.vnet_subnet_ids) > 0 ? "Deny" : "Allow"
  
  dynamic "virtual_network_subnet_ids" {
    for_each = var.vnet_subnet_ids
    content {
      subnet_id = virtual_network_subnet_ids.value
    }
  }
}

# ❌ WRONG - Event Grid does NOT support dynamic blocks for service_bus_*_endpoint_id
# dynamic "service_bus_queue_endpoint_id" {
#   for_each = var.service_bus_queue_id != null ? [1] : []
#   content { value = var.service_bus_queue_id }
# }

# ✅ CORRECT - Direct attributes for Event Grid
resource "azurerm_eventgrid_event_subscription" "main" {
  name                              = var.name
  scope                             = azurerm_eventgrid_domain.main.id
  service_bus_queue_endpoint_id     = var.service_bus_queue_id
  service_bus_topic_endpoint_id     = var.service_bus_topic_id
}
```

---

## Deprecated Attributes (Azure Provider 4.x)

### DO NOT USE - Deprecated in Provider 4.x
| Deprecated Attribute | Use Instead | Resource |
|---------------------|------------|----------|
| `enable_https_traffic_only` | `https_traffic_only_enabled` | Storage Account |
| `zone_redundant` | `premium_messaging_partitions` | Service Bus |
| `enable_partitioning` | Removed (namespace-level control) | Service Bus Queue/Topic |
| `metric` | `enabled_metric` | Diagnostic Settings |

### Validation
```bash
# Check for deprecated attributes
grep -n "enable_https_traffic_only\|zone_redundant\|enable_partitioning" terraform/
# Expected: Empty (no results)
```

---

## Terraform Workflow

### Local Development
```bash
# 1. Set environment variables
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_USE_AZUREAD=true  # For Storage Account Azure AD auth

# 2. Initialize with backend
cd terraform
terraform init \
  -backend-config="resource_group_name=rg-paas" \
  -backend-config="storage_account_name=storagepaas" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=myplatform.terraform.tfstate" \
  -backend-config="use_azuread_auth=true"

# 3. Validate syntax
terraform validate

# 4. Format code
terraform fmt -recursive

# 5. Plan changes
terraform plan -var-file=test.tfvars -out=tfplan

# 6. Apply changes
terraform apply tfplan
```

### Code Quality Checks
```bash
# Validation checklist
terraform validate                                                    # Syntax
terraform fmt -check -recursive                                       # Formatting
grep -r "random_string\|random_uuid" terraform/modules/              # No random names
grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name =" # All roles have names
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/             # No null checks in count
```

---

## Debugging Terraform Issues

### Enable Debug Logging
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan
```

### Common Errors & Solutions

#### "depends on resource attributes that cannot be determined"
**Cause**: Using resource attributes in `count` condition
```terraform
# ❌ WRONG
count = var.workspace_id != null ? 1 : 0

# ✅ CORRECT
count = var.enable_observability ? 1 : 0
```

#### "Error: Cycle: module.X, module.Y"
**Cause**: Circular dependency between modules
**Solution**: Refactor to root-level orchestration; remove inter-module dependencies

#### "Error: Key Vault has soft-delete enabled"
**Cause**: Trying to recreate soft-deleted Key Vault
**Solution**: Wait for purge period or manually purge via Azure CLI:
```bash
az keyvault purge --name <vault-name> --location eastus2
```

#### "Error: storage account already exists"
**Cause**: MD5 collision (extremely rare) or reusing same platform name
**Solution**: Change `var.name` to unique value

---

## Module Testing

### Test Configuration
```hcl
# test.tfvars
name                     = "testplatform"
subscription_id          = "00000000-0000-0000-0000-000000000000"
location                 = "eastus2"
environment              = "test"

# Feature flags
enable_managed_identity  = true
enable_vnet              = true
enable_observability     = true
enable_storage           = true
enable_service_bus       = false
enable_event_grid        = false
enable_sql               = false
enable_key_vault         = false
enable_container_apps    = false
enable_container_registry = true
container_registry_sku    = "Basic"

tags = {
  Project     = "Platform Stack"
  Environment = "Test"
  ManagedBy   = "Terraform"
}
```

### Test Workflow
```bash
# 1. Plan with test config
terraform plan -var-file=test.tfvars -out=test.tfplan

# 2. Review plan output
terraform show test.tfplan

# 3. Apply (if approved)
terraform apply test.tfplan

# 4. Validate outputs
terraform output

# 5. Destroy (after testing)
terraform destroy -var-file=test.tfvars -auto-approve
```

---

## Documentation Generation

### terraform-docs (Optional)
```bash
# Install
brew install terraform-docs  # macOS
choco install terraform-docs # Windows

# Generate README for module
cd terraform/modules/workloads/storage-account
terraform-docs markdown table . > README.md

# Generate for all modules
for dir in terraform/modules/*/*; do
  terraform-docs markdown table "$dir" > "$dir/README.md"
done
```

---

## File References

- **Backend Configuration**: [terraform/backend.tf](../../terraform/backend.tf)
- **Root Orchestration**: [terraform/main.tf](../../terraform/main.tf)
- **Feature Flags**: [terraform/variables.tf](../../terraform/variables.tf)
- **Naming Module**: [terraform/modules/foundation/naming/main.tf](../../terraform/modules/foundation/naming/main.tf)
- **Storage Module**: [terraform/modules/workloads/storage-account/main.tf](../../terraform/modules/workloads/storage-account/main.tf)
- **SQL Module**: [terraform/modules/workloads/sql/main.tf](../../terraform/modules/workloads/sql/main.tf)
- **Key Vault Module**: [terraform/modules/security/key-vault/main.tf](../../terraform/modules/security/key-vault/main.tf)
- **Container Registry Module (External)**: [tfmodules-as-a-service-stack/modules/azurerm_container_registry](https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack/tree/1.0.3/modules/azurerm_container_registry)

---

## MCP Query Examples

### Before Implementing Storage Account
```bash
# Step 1: Search documentation
microsoft_docs_search(query: "Azure Storage Account security best practices")

# Step 2: Get code samples
microsoft_code_sample_search(query: "azurerm_storage_account RBAC", language: "terraform")

# Step 3: Validate provider
mcp_hashicorp_ter_search_providers(query: "azurerm storage_account")
mcp_hashicorp_ter_get_provider_details(
  namespace: "hashicorp",
  name: "azurerm",
  type: "azurerm_storage_account"
)

# Step 4: Check existing patterns
semantic_search(query: "storage account RBAC role assignment")
```

### Before Implementing SQL Server
```bash
# Step 1: Microsoft docs
microsoft_docs_search(query: "Azure SQL Server managed identity authentication")

# Step 2: Provider details
mcp_hashicorp_ter_get_provider_details(
  namespace: "hashicorp",
  name: "azurerm",
  type: "azurerm_mssql_server"
)

# Step 3: Check diagnostic settings
mcp_hashicorp_ter_get_provider_details(
  namespace: "hashicorp",
  name: "azurerm",
  type: "azurerm_monitor_diagnostic_setting"
)
```
