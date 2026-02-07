---
name: terraform-platform-stack
description: Terraform specialist for Platform as a Service Stack v3.0.0+. Expert in deterministic naming (MD5), RBAC role assignments (uuidv5), feature flag orchestration, time-based RBAC propagation, and anti-pattern detection. Always validates with Terraform Registry MCP before ANY code generation to ensure latest provider schemas and avoid deprecated attributes.
---

# Terraform Platform Stack Specialist

## Overview

This skill provides expert guidance for Terraform infrastructure as code development in the **Platform as a Service Stack v3.0.0+** environment. It focuses on deterministic patterns (MD5 naming, uuidv5 RBAC), feature flag orchestration, root-level module coordination, and strict adherence to platform anti-pattern rules.

## When to Use This Skill

- Creating new Terraform modules for Platform Stack workloads
- Implementing feature flags with proper dependency validation
- Refactoring code to eliminate anti-patterns (random_string, null checks in count)
- Debugging "depends on resource attributes" errors
- Implementing RBAC with deterministic uuidv5() role assignments
- Adding time_sleep for RBAC propagation (180s delays)
- Orchestrating modules at root main.tf level (no inter-module dependencies)
- Validating Azure Provider 4.x compatibility (deprecated attributes)
- Troubleshooting RBAC propagation failures
- Optimizing Terraform state with boolean flags (not null checks)

## MANDATORY: MCP Integration Workflow

**BEFORE writing/modifying ANY Terraform code, you MUST execute this workflow:**

### Step 1: Check Provider/Module Versions (REQUIRED)

```
Use mcp_hashicorp_ter_get_latest_provider_version:
- Provider: azurerm, azuread, kubernetes, helm, etc.
- Purpose: Get current version for ~> constraint
- NEVER guess versions

Use mcp_hashicorp_ter_get_latest_module_version:
- Namespace: <registry namespace>
- Name: <module name>
- Provider: <provider name>
- Purpose: Check latest module version if using registry modules
```

**Example workflow:**
```
1. Get version: azurerm provider
2. Result: "4.51.0" → use "~> 4.51.0"
3. Get version: azuread provider
4. Result: "3.1.0" → use "~> 3.1.0"
```

### Step 2: Consult Provider/Module Documentation (REQUIRED)

```
Use mcp_hashicorp_ter_search_providers:
- Provider name: "azurerm"
- Service slug: "<resource-type>" (e.g., "kubernetes_cluster", "storage_account")
- Provider namespace: "hashicorp"
- Provider document type: "resources" (for creating) or "data-sources" (for reading)
- Purpose: Find exact resource documentation

Use mcp_hashicorp_ter_get_provider_details:
- Provider doc ID: <from search results>
- Purpose: Get complete resource schema, arguments, examples
- NEVER skip this - it prevents incorrect argument usage
```

**Example workflow:**
```
1. Search: provider="azurerm", service="kubernetes_cluster", type="resources"
2. Get doc ID from results
3. Get details: Complete azurerm_kubernetes_cluster schema
4. Verify: required vs optional arguments
5. Review: official examples
```

**For modules:**
```
Use mcp_hashicorp_ter_search_modules:
- Query: "<module purpose>"
- Provider: "azure" or specific provider
- Purpose: Find existing public registry modules

Use mcp_hashicorp_ter_get_module_details:
- Module namespace/name/provider: from search
- Purpose: Get usage documentation, inputs, outputs
```

### Step 3: Review Workspace Patterns (REQUIRED)

```
Use grep_search or semantic_search:
- Search for: similar resource types in *.tf files
- Purpose: Maintain consistency with existing patterns

Read relevant workspace files:
- backend.tf - State configuration pattern
- providers.tf - Provider alias patterns
- variables.tf - Variable declaration standards
- modules/terraform-azurerm-*/ - Module structure examples
```

## Critical Platform Stack Standards

### State Management (Azure Blob with Azure AD)

**ALL projects use Azure Blob Storage with Azure AD authentication:**

```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "platform.terraform.tfstate"  # Override per platform
    use_azuread_auth     = true  # MANDATORY (no access keys)
  }
}
```

**Initialization (CLI)**:
```bash
terraform init \
  -backend-config="key=myplatform.terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
```

### Module Structure (Single Concern)

**Standard module layout**:
```
terraform/modules/{domain}/{resource}/
├── main.tf         # Resource + RBAC + network rules
├── variables.tf    # name, location, tags, managed_identity_principal_id
├── outputs.tf      # IDs, URIs, names (NO secret values)
```

**Root orchestration ONLY** (terraform/main.tf):
```hcl
module "storage" {
  count = var.enable_storage ? 1 : 0
  
  source                        = "./modules/workloads/storage-account"
  name                          = module.naming.storage_account
  location                      = var.location
  resource_group_name           = module.resource_group.name
  managed_identity_principal_id = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  vnet_subnet_ids               = var.enable_vnet ? [module.vnet_spoke[0].default_subnet_id] : []
  tags                          = var.tags
}
```

**CRITICAL**: Modules NEVER reference other modules - orchestration at root only!

### Anti-Patterns (FORBIDDEN)

**Detect with grep before committing**:

```bash
# 1. No random_string/random_uuid (use MD5)
grep -r "random_string\|random_uuid" terraform/modules/

# 2. All role assignments MUST have 'name' (use uuidv5)
grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="

# 3. No null checks in count (use boolean flags)
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/

# 4. No inter-module dependencies
grep -n "module\\..*\\..*=" terraform/modules/

# 5. No dynamic blocks in Event Grid
grep -n "dynamic" terraform/modules/workloads/event-grid/ | grep "service_bus"
```

**If any grep returns results**: Fix before commit!

### Count Conditions (Boolean Flags ONLY)

```hcl
# ❌ WRONG - Causes "depends on resource attributes" error
count = var.log_analytics_workspace_id != null ? 1 : 0

# ✅ CORRECT - Use boolean flag
count = var.enable_observability ? 1 : 0

# Root main.tf passes workspace_id directly (not via count)
module "container_apps" {
  count = var.enable_container_apps ? 1 : 0
  
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].workspace_id : null
}
```

**Rule**: Count conditions ONLY accept boolean variables. NO null checks, NO string comparisons.

### Deterministic Patterns

**1. MD5 Naming (NOT random_string)**:
```hcl
# ❌ WRONG - Destroys resources on re-apply
resource "random_string" "suffix" {
  length = 4
}

locals {
  name = "${var.name}-${random_string.suffix.result}"  # Changes every apply!
}

# ✅ CORRECT - Deterministic MD5
locals {
  md5_suffix = substr(md5(var.name), 0, 4)  # Same input = same output
  name       = "${var.name}-${local.md5_suffix}"
}
```

**2. uuidv5 Role Assignments (NOT omitting name)**:
```hcl
# ❌ WRONG - Azure generates random UUID
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_resource.main.id
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
  # No 'name' = Azure assigns random ID = destroy/recreate cycle
}

# ✅ CORRECT - Deterministic uuidv5
resource "azurerm_role_assignment" "example" {
  name                 = uuidv5("dns", "${azurerm_resource.main.id}-${var.principal_id}-contributor")
  scope                = azurerm_resource.main.id
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
}
```

**3. RBAC Propagation (180s time_sleep)**:
```hcl
# ❌ WRONG - Secret created before RBAC propagates
resource "azurerm_key_vault_secret" "example" {
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.admin]  # Not enough!
}

# ✅ CORRECT - Add time_sleep
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.admin]
  create_duration = "180s"
  
  triggers = {
    role_assignment_id = azurerm_role_assignment.admin.id
  }
}

resource "azurerm_key_vault_secret" "example" {
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [time_sleep.wait_for_rbac]  # Wait for propagation
}
```

### State Management (CRITICAL)

**ALL projects use Azure Blob Storage remote state - NEVER local state**

```terraform
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stapplicationsautomation"
    container_name       = "tfstate"
    key                  = "<project>-<tenant>-<environment>.tfstate"

    # Credentials via environment variables:
    # ARM_SUBSCRIPTION_ID
    # ARM_TENANT_ID
    # ARM_CLIENT_ID
    # ARM_CLIENT_SECRET
  }
}
```

**State file naming convention:** `<project>-<tenant>-<environment>.tfstate`

**Examples:**
- `aks-na-prod.tfstate`
- `network-stack-prod.tfstate`
- `workers-backend-sophie-dev.tfstate`

**State initialization:**
```bash
terraform init -backend-config="key=<project>-<tenant>-<environment>.tfstate"
```

### Multi-Tenant Configuration Architecture

**Configuration layering (hub-and-spoke pattern):**

```
project-root/
├── backend.tf
├── providers.tf
├── main.tf
├── variables.tf
├── cluster-config/
│   ├── common/
│   │   └── main.tfvars          # Base configuration for ALL tenants
│   └── specific/
│       ├── na/
│       │   ├── dev.tfvars       # NA dev overrides
│       │   ├── qa.tfvars        # NA qa overrides
│       │   └── prod.tfvars      # NA prod overrides
│       ├── sophie/
│       │   ├── dev.tfvars
│       │   └── prod.tfvars
│       └── woopi/
│           └── prod.tfvars
└── modules/
    └── <custom-modules>/
```

**Usage pattern:**
```bash
# Apply with layered configs
terraform plan \
  -var-file="cluster-config/common/main.tfvars" \
  -var-file="cluster-config/specific/na/prod.tfvars"

terraform apply \
  -var-file="cluster-config/common/main.tfvars" \
  -var-file="cluster-config/specific/na/prod.tfvars"
```

**Variable naming for multi-tenant:**
```terraform
# Prefix tenant-specific variables
variable "na_subscription_id" {
  description = "North America subscription ID"
  type        = string
  sensitive   = true
}

variable "sophie_subscription_id" {
  description = "Sophie tenant subscription ID"
  type        = string
  sensitive   = true
}

# OR use maps for shared structure
variable "subscription_ids" {
  description = "Subscription IDs per tenant"
  type        = map(string)
  sensitive   = true

  default = {
    na     = ""
    sophie = ""
    woopi  = ""
  }
}
```

### Version Constraints (CRITICAL)

**ALWAYS pin versions with `~>` constraint:**

```terraform
# versions.tf
terraform {
  required_version = "~> 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"    # Allows patch updates (4.51.x)
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31.0"
    }
  }
}
```

**Version constraint rules:**
- ✅ Use `~> 4.51.0` - allows patch updates (4.51.1, 4.51.2)
- ❌ NEVER use `>= 3.0` - unpinned, breaks reproducibility
- ❌ NEVER use `= 4.51.0` - exact pin, too restrictive
- ❌ NEVER omit version - breaks state compatibility

**Before upgrading providers:**
1. Check latest version: `mcp_hashicorp_ter_get_latest_provider_version`
2. Review CHANGELOG for breaking changes
3. Test in dev environment first
4. Update all modules to compatible versions

### File Structure Standards

**Standard project organization:**
```
project-root/
├── backend.tf        # Remote state configuration
├── providers.tf      # Provider configurations with aliases
├── versions.tf       # Terraform and provider version constraints
├── variables.tf      # Input variable declarations
├── locals.tf         # Local values and computed variables
├── main.tf           # Primary resource definitions
├── network.tf        # Networking resources (optional)
├── outputs.tf        # Output declarations
├── *.tfvars          # Variable values (NOT in git if contains secrets)
└── modules/          # Local modules
    └── <module-name>/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

**File-specific guidelines:**

**backend.tf:**
```terraform
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stapplicationsautomation"
    container_name       = "tfstate"
    key                  = "will-be-overridden-at-runtime.tfstate"
  }
}
```

**providers.tf:**
```terraform
terraform {
  required_version = "~> 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
}

# Multiple provider configurations with aliases
provider "azurerm" {
  alias           = "stefanininam"
  subscription_id = var.stefanininam_subscription_id
  tenant_id       = var.stefanininam_tenant_id
  client_id       = var.stefanininam_client_id
  client_secret   = var.stefanininam_client_secret
  features {}
}

provider "azurerm" {
  alias           = "devops"
  subscription_id = var.devops_subscription_id
  tenant_id       = var.devops_tenant_id
  client_id       = var.devops_client_id
  client_secret   = var.devops_client_secret
  features {}
}
```

**variables.tf:**
```terraform
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "tenant" {
  description = "Tenant identifier"
  type        = string

  validation {
    condition     = contains(["na", "sophie", "woopi", "dex"], var.tenant)
    error_message = "Tenant must be na, sophie, woopi, or dex."
  }
}

variable "client_secret" {
  description = "Azure service principal client secret"
  type        = string
  sensitive   = true  # ALWAYS mark secrets as sensitive
}
```

**locals.tf:**
```terraform
locals {
  resource_prefix = "${var.tenant}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Tenant      = var.tenant
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  )

  location_short = {
    "East US"     = "eus"
    "West Europe" = "weu"
  }
}
```

**outputs.tf:**
```terraform
# Output complete resource object
output "resource_group" {
  description = "Complete resource group object"
  value       = azurerm_resource_group.main
}

# Output specific attributes
output "resource_group_id" {
  description = "Resource group ID"
  value       = azurerm_resource_group.main.id
}

# Output JSON summary
output "resource_summary" {
  description = "JSON summary of key attributes"
  value = jsonencode({
    id       = azurerm_resource_group.main.id
    name     = azurerm_resource_group.main.name
    location = azurerm_resource_group.main.location
  })
}

# Sensitive outputs
output "connection_string" {
  description = "Database connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true  # ALWAYS mark secrets as sensitive
}
```

## Module Development Standards

**Module directory structure:**
```
modules/terraform-azurerm-<resource>/
├── README.md              # Module documentation
├── main.tf                # Resource logic
├── variables.tf           # Input declarations with validation
├── outputs.tf             # Output declarations
├── versions.tf            # Provider version constraints
├── locals.tf              # Local computations (optional)
└── examples/
    └── basic/
        ├── main.tf
        └── terraform.tfvars.example
```

**Module best practices:**

**variables.tf:**
```terraform
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string

  validation {
    condition     = contains(["eastus", "westus", "westeurope"], var.location)
    error_message = "Location must be a supported region."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Provider alias support
variable "providers" {
  description = "Provider configuration"
  type = object({
    azurerm = any
  })
  default = null
}
```

**main.tf:**
```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
      configuration_aliases = [azurerm.main]  # Support provider aliases
    }
  }
}

resource "azurerm_storage_account" "main" {
  provider = var.providers != null ? var.providers.azurerm : azurerm.main

  name                     = "st${var.name}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  tags = merge(
    var.tags,
    {
      Module = "terraform-azurerm-storage"
    }
  )
}
```

**outputs.tf:**
```terraform
# Output complete resource object (most flexible)
output "storage_account" {
  description = "Complete storage account resource object"
  value       = azurerm_storage_account.main
}

# Output specific commonly-used attributes
output "id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

# Output JSON summary
output "summary" {
  description = "Storage account summary"
  value = jsonencode({
    id                  = azurerm_storage_account.main.id
    name                = azurerm_storage_account.main.name
    primary_endpoint    = azurerm_storage_account.main.primary_blob_endpoint
    primary_access_key  = "***SENSITIVE***"
  })
}

# Sensitive outputs
output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}
```

**README.md template:**
```markdown
# Terraform Azure <Resource> Module

## Description
Brief description of what this module creates and its purpose.

## Usage
\`\`\`hcl
module "storage" {
  source = "./modules/terraform-azurerm-storage"

  name                = "myapp"
  environment         = "prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    Environment = "Production"
  }
}
\`\`\`

## Inputs
<!-- Auto-generated with: terraform-docs markdown . > README.md -->

## Outputs
<!-- Auto-generated with: terraform-docs markdown . > README.md -->

## Requirements
- Terraform >= 1.9.0
- azurerm provider ~> 4.51.0

## Examples
See [examples/basic](./examples/basic) for a complete example.
```

## Common Implementation Tasks

### 1. Creating New Resource Configuration

**MCP workflow:**
1. Get latest provider version: `mcp_hashicorp_ter_get_latest_provider_version`
2. Search for resource: `mcp_hashicorp_ter_search_providers`
3. Get resource details: `mcp_hashicorp_ter_get_provider_details`
4. Review workspace patterns: `grep_search` or `semantic_search`

**Implementation:**
```terraform
# Variable declarations
variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_account_replication)
    error_message = "Must be a valid replication type."
  }
}

# Resource with environment-specific logic
resource "azurerm_storage_account" "data" {
  provider                 = azurerm.stefanininam
  name                     = "st${var.tenant}${var.app_name}${var.environment}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"

  # Dynamic configuration based on environment
  min_tls_version               = "TLS1_2"
  enable_https_traffic_only     = true
  allow_nested_items_to_be_public = false

  network_rules {
    default_action = var.environment == "prod" ? "Deny" : "Allow"
    ip_rules       = var.allowed_ips
    bypass         = ["AzureServices"]
  }

  tags = local.common_tags
}

# Outputs
output "storage_account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.data.id
}
```

### 2. Debugging Terraform Issues

**State Lock Issues:**

**Symptoms:**
- "Error: Error locking state"
- "Error: state blob is already locked"

**MCP workflow:**
1. Search: "Terraform Azure blob storage state lock troubleshooting"

**Resolution:**
```powershell
# Check blob lease status
az storage blob show `
  --account-name stapplicationsautomation `
  --container-name tfstate `
  --name <project>-<tenant>-<environment>.tfstate `
  --query "properties.lease" `
  --auth-mode login

# If lease is "locked", verify no one is running terraform
# Contact team to confirm

# Break lease (CAUTION)
az storage blob lease break `
  --blob-name <project>-<tenant>-<environment>.tfstate `
  --container-name tfstate `
  --account-name stapplicationsautomation `
  --auth-mode login
```

**Plan Failures:**

**Symptoms:**
- "Error: Unsupported argument"
- "Error: Invalid value for variable"
- "Error: Cycle" (circular dependency)

**MCP workflow:**
1. Get provider details for resource: `mcp_hashicorp_ter_get_provider_details`
2. Search docs: "Terraform <error-message>"

**Debugging steps:**
```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan

# Review log for specific error
grep -i "error" terraform-debug.log

# Visualize dependencies (for cycle errors)
terraform graph | dot -Tpng > graph.png

# Validate syntax
terraform validate

# Check provider versions
terraform version
terraform providers
```

**Resource Already Exists:**

**Symptoms:**
- "Error: A resource with the ID /subscriptions/... already exists"

**Options:**

**Option 1: Import existing resource**
```bash
# Get resource ID from Azure
az resource show --resource-group <rg> --name <name> --resource-type <type> --query id -o tsv

# Import into Terraform state
terraform import azurerm_resource_group.main "/subscriptions/<sub-id>/resourceGroups/<rg-name>"

# Verify import successful
terraform plan  # Should show no changes or only minor updates
```

**Option 2: Remove from state (if recreating)**
```bash
terraform state rm azurerm_resource_group.main
```

**State Drift:**

**Symptoms:**
- Terraform plan shows unexpected changes
- Manual changes were made in Azure Portal

**Detection:**
```bash
# Refresh state from actual resources
terraform refresh

# Detect drift
terraform plan -detailed-exitcode
# Exit code 0 = no changes
# Exit code 1 = error
# Exit code 2 = changes detected (drift)

# Show specific drift
terraform show

# For detailed diff
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq '.resource_changes'
```

**Resolution:**
```bash
# Option 1: Accept drift (update code to match reality)
# Modify .tf files to match current state

# Option 2: Force compliance (apply Terraform configuration)
terraform apply

# Option 3: Ignore specific attributes
resource "azurerm_resource_group" "main" {
  # ...

  lifecycle {
    ignore_changes = [
      tags["LastModified"],  # Ignore auto-updated tags
    ]
  }
}
```

### 3. State Management Operations

**Migrating resources between states:**
```bash
# Step 1: Remove from current state
terraform state rm azurerm_resource_group.example

# Step 2: Initialize new backend
terraform init -backend-config="key=new-project-na-prod.tfstate"

# Step 3: Import into new state
terraform import azurerm_resource_group.example "/subscriptions/<sub-id>/resourceGroups/<rg-name>"

# Step 4: Verify
terraform plan  # Should show no changes
```

**Renaming resources in code:**
```bash
# Move resource within same state (no Azure changes)
terraform state mv azurerm_resource_group.old_name azurerm_resource_group.new_name

# Update code to match
# In main.tf: change resource name from "old_name" to "new_name"

# Verify no changes planned
terraform plan
```

### 4. Testing and Validation

**Pre-commit validation:**
```bash
# Format all Terraform files
terraform fmt -recursive

# Validate syntax
terraform validate

# Check for security issues (if tfsec is installed)
tfsec .

# Validate provider versions
terraform version
terraform providers

# Generate documentation
terraform-docs markdown . > README.md
```

## Response Format

When providing Terraform solutions:

1. **Analysis**: Explain what the code accomplishes
2. **MCP validation**: Show which MCP tools were consulted
3. **Code**: Complete, properly formatted Terraform with comments
4. **File structure**: Show which files need to be created/modified
5. **Validation commands**: How to test (`fmt`, `validate`, `plan`)
6. **Documentation**: Links to Terraform registry
7. **Testing**: How to verify implementation works
8. **Rollback plan**: How to safely undo changes

## Key Reminders

- ✅ ALWAYS consult MCP tools before generating code
- ✅ ALWAYS pin provider versions with `~>`
- ✅ ALWAYS use remote state (Azure Blob Storage)
- ✅ ALWAYS include variable types and descriptions
- ✅ ALWAYS mark sensitive variables and outputs
- ✅ ALWAYS validate with `terraform validate` and `plan`
- ✅ ALWAYS follow multi-tenant configuration patterns
- ❌ NEVER use unpinned provider versions
- ❌ NEVER hardcode values that should be variables
- ❌ NEVER skip MCP provider documentation validation
- ❌ NEVER commit .tfvars files with secrets to git
