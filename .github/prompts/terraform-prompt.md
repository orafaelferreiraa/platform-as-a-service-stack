---
name: terraform
description: Generate Terraform code for Platform as a Service Stack with MCP validation
argument-hint: "[module|refactor|debug|validate] [component-name] [feature-flag]"
agent: Terraform Platform Expert
model: Claude Sonnet 4
tools:
  - mcp_hashicorp
  - mcp_microsoftdocs
  - read_file
  - grep_search
  - semantic_search
  - multi_replace_string_in_file
  - create_file
  - run_in_terminal
---

# Terraform Code Operations - Platform as a Service Stack

You are generating or fixing Terraform code for the **Platform as a Service Stack v3.0.0+**. **Always follow this workflow**:

## 1. Validate with MCP (MANDATORY BEFORE CODE GENERATION)

### Provider Version Check:
```
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "azurerm")
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "random")
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "time")
```

### Resource Schema Validation:
```
mcp_hashicorp_ter_search_providers(query: "azurerm ${input:component-name}")
mcp_hashicorp_ter_get_provider_details(
  namespace: "hashicorp",
  name: "azurerm",
  type: "azurerm_${input:component-name}"
)
```

### Microsoft Documentation:
```
microsoft_docs_search(query: "Azure ${input:component-name} best practices")
microsoft_code_sample_search(query: "azurerm_${input:component-name}", language: "terraform")
```

## 2. Load Platform Stack Context Files
Read these instruction files:
- [.github/instructions/terraform-platform-instructions.md](../instructions/terraform-platform-instructions.md)
- [.github/instructions/azure-instructions.md](../instructions/azure-instructions.md)
- [.github/copilot-instructions.md](../copilot-instructions.md)

## 3. Platform Stack Architecture Context

### Fixed Configuration
- **Terraform Version**: >= 1.9.0
- **Provider Versions**: azurerm ~> 4.57.0, random ~> 3.8.0, time ~> 0.13.0
- **Region**: eastus2 (hardcoded)
- **State Backend**: Azure Blob Storage with `use_azuread_auth = true`

### Critical Patterns (Non-Negotiable)
1. **Deterministic Naming**: `substr(md5(var.name), 0, 4)` - NEVER `random_string`
2. **RBAC Role Assignments**: `name = uuidv5("dns", "${scope}-${principal}-{role}")` - NEVER omit
3. **RBAC Propagation**: 180s `time_sleep` REQUIRED before secrets/containers
4. **Count Conditions**: Boolean flags ONLY - NEVER `!= null` checks
5. **Module Orchestration**: Root main.tf ONLY - NEVER inter-module dependencies

## 5. Task Execution

### If Creating Module:
```
terraform/modules/workloads/${input:component-name}/
├── main.tf         # Resource + RBAC + network rules
├── variables.tf    # name, location, tags, managed_identity_principal_id
├── outputs.tf      # IDs, URIs, names (NO secret values)
```

**MANDATORY Module Pattern**:
```hcl
# variables.tf
variable "name" {
  description = "Resource name from naming module"
  type        = string
}

variable "managed_identity_principal_id" {
  description = "Principal ID for RBAC assignments (optional)"
  type        = string
  default     = null
}

# main.tf
resource "azurerm_${input:component-name}" "main" {
  name                = var.name  # From naming module
  location            = var.location
  r6. Output Format

Provide:
- ✅ Complete module structure (main.tf, variables.tf, outputs.tf)
- ✅ Feature flag addition in root variables.tf
- ✅ Module call in root main.tf with orchestration
- ✅ RBAC implementation with uuidv5()
- ✅ time_sleep for RBAC propagation (if applicable)
- ✅ Validation commands and anti-pattern checks
- ✅ Links to similar modules: [storage-account/main.tf](terraform/modules/workloads/storage-account/main.tf)

## 7. Validation Steps (MANDATORY)

Run these commands before suggesting code:
```bash
# Anti-pattern detection
grep -r "random_string\|random_uuid" terraform/modules/${input:component-name}/
grep -n "azurerm_role_assignment" terraform/modules/${input:component-name}/ | grep -v "name ="
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/modules/${input:component-name}/

# Terraform validation
cd terraform
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=test.tfvars
```

---

## Example Usage

```
/terraform module redis-cache
/terraform refactor storage-account --add-rbac-delay
/terraform debug "depends on resource attributes"
/terraform validate feature-flags
```

## Variables Available
- `${input:operation}` - Operation: module, refactor, debug, validate
- `${input:component-name}` - Resource/module name (e.g., storage-account, redis-cache)
- `${input:feature-flag}` - Feature flag name (e.g., enable_redis)
- `${file}` - Current file path
- `${selection}` - Selected code/text

## Critical Platform Stack Rules
- ❌ NEVER use random_string or random_uuid (use MD5)
- ❌ NEVER omit 'name' in azurerm_role_assignment (use uuidv5)
- ❌ NEVER skip time_sleep for RBAC (180s required)
- ❌ NEVER use != null in count (use boolean flags)
- ❌ NEVER create inter-module dependencies (orchestrate at root)
- ❌ NEVER export secret values in outputs (only IDs/URIs)
- ❌ NEVER use unpinned provider versions
- ✅ ALWAYS validate via MCP before generating code
- ✅ ALWAYS use naming module outputs for resource names
- ✅ ALWAYS use RBAC-first security (no shared keys)
- ✅ ALWAYS add lifecycle prevent_destroy for critical resources
- ✅ ALWAYS orchestrate modules in root main.tf only
- ✅ ALWAYS run anti-pattern checks before submit
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Must be dev, qa, or prod."
  }
}

variable "client_secret" {
  description = "Azure service principal secret"
  type        = string
  sensitive   = true
}
```

### Outputs:
```hcl
output "resource" {
  description = "Complete resource object"
  value       = azurerm_storage_account.main
}

output "resource_summary" {
  description = "JSON summary"
  value = jsonencode({
    id   = azurerm_storage_account.main.id
    name = azurerm_storage_account.main.name
  })
}
```

### Locals:
```hcl
locals {
  resource_prefix = "${var.tenant}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}
```

## 6. Output Format

Provide:
- ✅ Complete file structure (backend, main, variables, outputs, versions)
- ✅ Provider versions pinned with ~>
- ✅ Variables with types, descriptions, validation
- ✅ Usage examples with real commands
- ✅ Validation commands: `terraform validate`, `terraform fmt`, `terraform plan`
- ✅ Documentation generation: `terraform-docs markdown . > README.md`

## 7. Validation Steps

Run these commands:
```bash
# Format check
terraform fmt -check -recursive

# Syntax validation
terraform validate

# Plan with layered configs
terraform plan \
  -var-file="cluster-config/common/main.tfvars" \
  -var-file="cluster-config/specific/${input:tenant}/${input:environment}.tfvars"
```

---

## Example Usage

```
/terraform module storage-account na
/terraform resource aks-cluster sophie prod
/terraform refactor ${file} --extract-module
/terraform debug "Backend initialization required"
```

## Variables Available
- `${input:operation}` - Operation: module, resource, refactor, debug
- `${input:component-name}` - Resource/module name
- `${input:tenant}` - Tenant: na, sophie, woopi, dex
- `${input:environment}` - Environment: dev, qa, prod
- `${file}` - Current file path
- `${selection}` - Selected code/text

## Critical Rules
- ❌ NEVER generate code without MCP validation
- ❌ NEVER use unpinned provider versions
- ❌ NEVER omit variable types
- ❌ NEVER hardcode values that should be variables
- ✅ ALWAYS validate provider via MCP first
- ✅ ALWAYS use ~> constraint for versions
- ✅ ALWAYS include both resource object and JSON outputs
- ✅ ALWAYS run terraform validate before suggesting
