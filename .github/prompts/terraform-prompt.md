---
name: terraform
description: Generate Terraform code for Platform as a Service Stack with MCP validation
argument-hint: "[module|refactor|debug|validate] [component-name] [feature-flag]"
agent: Terraform Platform Expert
model: Claude Opus 4
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

## 3. Task Execution

### If Creating Module:
```
terraform/modules/workloads/${input:component-name}/
├── main.tf         # Resource + RBAC + network rules
├── variables.tf    # name, location, tags, managed_identity_principal_id
├── outputs.tf      # Names, FQDNs, URIs (NO resource IDs, NO secret values)
```

### If Using External Module (e.g., Container Registry):
External modules live in separate repos and are sourced via git ref:
```hcl
module "container_registry" {
  count  = var.enable_container_registry ? 1 : 0
  source = "git::https://github.com/orafaelferreiraa/tfmodules-as-a-service-stack.git//modules/azurerm_container_registry?ref=1.0.3"

  name     = module.naming.container_registry_name  # cr{name}{region}{md5}
  location = var.location
  tags     = local.common_tags
  sku      = var.container_registry_sku
}
```
- **RBAC**: AcrPush + AcrPull assigned to Managed Identity via `uuidv5("dns", "...")`
- **Container Apps zero-config**: MI pre-attached + ACR `login_server` passed through
- **Output**: Individual outputs for environment name/domain/IP and registry name/login_server (no composite output with IDs)

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

```

## 4. Output Format

Provide:
- ✅ Complete module structure (main.tf, variables.tf, outputs.tf)
- ✅ Feature flag addition in root variables.tf
- ✅ Module call in root main.tf with orchestration
- ✅ RBAC implementation with uuidv5()
- ✅ time_sleep for RBAC propagation (if applicable)
- ✅ Validation commands and anti-pattern checks
- ✅ Links to similar modules: [storage-account/main.tf](terraform/modules/workloads/storage-account/main.tf)

## 5. Validation Steps (MANDATORY)

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
- ❌ NEVER export resource IDs in outputs (they contain subscription ID)
- ❌ NEVER export secret values in outputs
- ❌ NEVER use unpinned provider versions
- ❌ NEVER inline external modules without pinned git ref
- ✅ ALWAYS validate via MCP before generating code
- ✅ ALWAYS use naming module outputs for resource names
- ✅ ALWAYS use RBAC-first security (no shared keys)
- ✅ ALWAYS add lifecycle prevent_destroy for critical resources
- ✅ ALWAYS orchestrate modules in root main.tf only
- ✅ ALWAYS run anti-pattern checks before submit
- ✅ ALWAYS source Container Registry from external module (`tfmodules-as-a-service-stack`)
- ✅ ALWAYS assign AcrPush + AcrPull RBAC to Managed Identity for Container Registry
