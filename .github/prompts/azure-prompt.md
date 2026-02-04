---
name: azure
description: Create or troubleshoot Azure resources for Platform as a Service Stack with MCP validation
argument-hint: resource-type [operation] [feature-flags]
agent: Azure Platform Expert
model: Claude Sonnet 4
tools:
  - mcp_microsoftdocs
  - mcp_hashicorp
  - read_file
  - grep_search
  - semantic_search
  - multi_replace_string_in_file
---

# Azure Resource Operations - Platform as a Service Stack

You are helping with Azure infrastructure for the **Platform as a Service Stack v3.0.0+**. **Always follow this workflow**:

## 1. Consult MCP Documentation (MANDATORY)

### Microsoft Documentation:
```
microsoft_docs_search(query: "Azure ${input:resource-type} security best practices")
microsoft_code_sample_search(query: "azurerm_${input:resource-type}", language: "terraform")
microsoft_docs_fetch(url: "[specific doc URL if needed]")
```

### Terraform Provider Validation:
```
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "azurerm")
mcp_hashicorp_ter_search_providers(query: "azurerm ${input:resource-type}")
mcp_hashicorp_ter_get_provider_details(
  namespace: "hashicorp",
  name: "azurerm",
  type: "azurerm_${input:resource-type}"
)
```

## 2. Load Platform Stack Context Files
Read these instruction files:
- [.github/instructions/azure-instructions.md](../instructions/azure-instructions.md)
- [.github/copilot-instructions.md](../copilot-instructions.md)

## 3. Check Existing Platform Patterns
Use semantic_search and grep_search:
- Search: `resource "azurerm_${input:resource-type}"` in `terraform/modules/`
- Identify: RBAC patterns (uuidv5), time_sleep delays, naming module usage

## 4. Platform Stack Architecture Context

### Fixed Configuration
- **Region**: `eastus2` (hardcoded, not configurable)
- **Location Abbreviation**: `eus2`
- **Naming Convention**: `{name}-{location_abbr}-{md5_suffix}`
- **Provider**: azurerm ~> 4.57.0 with `storage_use_azuread = true`

### Critical Patterns
1. **Deterministic Naming**: `substr(md5(var.name), 0, 4)` - NEVER `random_string`
2. **RBAC Role Assignments**: `uuidv5("dns", "${scope}-${principal}-{role}")` - NEVER omit `name`
3. **RBAC Propagation**: 180s `time_sleep` REQUIRED before secrets/containers
4. **Count Conditions**: Boolean flags ONLY - NEVER `!= null` checks

## 5. Task Execution

### If Creating New Module:
1. **Research with MCP** (execute queries above)
2. **Find similar module pattern**:
   ```bash
   grep_search(query: "resource \"azurerm_storage_account\"", includePattern: "terraform/modules/workloads/**")
   ```
3. **Create module structure**:
   ```
   terraform/modules/workloads/${input:resource-type}/
   ├── main.tf         # Resource + RBAC + network rules
   ├── variables.tf    # name, location, tags, managed_identity_principal_id
   ├── outputs.tf      # id, name, endpoints (NO secrets)
   ```
4. **Add feature flag**:
   ```hcl
   # terraform/variables.tf
   variable "enable_${input:resource-type}" {
     description = "Enable ${input:resource-type}"
     type        = bool
     default     = true
   }
   ```
5. **Orchestrate in root main.tf**:
   ```hcl
   module "${input:resource-type}" {
     count = var.enable_${input:resource-type} ? 1 : 0
     source = "./modules/workloads/${input:resource-type}"
     name   = module.naming.${input:resource-type}
     # ... pass dependencies via root
   }
   ```

### If Implementing Resource (within module):

**MANDATORY Pattern**:
```hcl
# Use naming module output
resource "azurerm_${input:resource-type}" "main" {
  name                = var.name  # From naming module
  location            = var.location
  resource_group_name = var.resource_group_name
  
  # Security: RBAC-first (no shared keys)
  # Example for Storage: shared_access_key_enabled = false
  # Example for Key Vault: rbac_authorization_enabled = true
  
  tags = var.tags
  
  lifecycle {
    prevent_destroy = true  # For critical resources
  }
}

# RBAC with deterministic name
resource "azurerm_role_assignment" "mi_role" {
  name                 = uuidv5("dns", "${azurerm_${input:resource-type}.main.id}-${var.managed_identity_principal_id}-contributor")
  scope                = azurerm_${input:resource-type}.main.id
  role_definition_name = "Contributor"
  principal_id         = var.managed_identity_principal_id
}

# RBAC propagation delay
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.mi_role]
  create_duration = "180s"
  triggers = {
    role_assignment_id = azurerm_role_assignment.mi_role.id
  }
}

# Dependent resources AFTER time_sleep
resource "azurerm_${input:resource-type}_secret" "example" {
  # ...
  depends_on = [time_sleep.wait_for_rbac]
}
```

### If Troubleshooting:

**Common Platform Stack Errors**:

1. **"Key based authentication is not permitted"**
   - **Cause**: Storage Account `shared_access_key_enabled = false` but provider missing `storage_use_azuread = true`
   - **Solution**: Add to provider block in providers.tf

2. **"does not have secrets get permission on key vault"**
   - **Cause**: Missing `time_sleep` or `rbac_authorization_enabled = false`
   - **Solution**: Add 180s time_sleep + ensure `rbac_authorization_enabled = true`

3. **"ManagedEnvironmentSubnetIsDelegated"**
   - **Cause**: Container Apps subnet delegated but no `workload_profile` block
   - **Solution**: Add workload_profile when using /27 delegated subnet

4. **"depends on resource attributes that cannot be determined"**
   - **Cause**: Using `!= null` in count condition
   - **Solution**: Use boolean flag: `count = var.enable_X ? 1 : 0`

**Debugging Steps**:
1. Search Microsoft Docs via MCP for error message
2. Check provider configuration in terraform/providers.tf
3. Verify RBAC propagation (180s time_sleep exists)
4. Validate feature flag dependencies

## 6. Output Format

Provide:
- ✅ Complete module code (main.tf, variables.tf, outputs.tf)
- ✅ Feature flag addition in root variables.tf
- ✅ Module call in root main.tf with proper orchestration
- ✅ RBAC implementation with uuidv5()
- ✅ time_sleep for RBAC propagation (if needed)
- ✅ Validation commands: `terraform validate`, `terraform plan`
- ✅ Links to similar modules: [storage-account/main.tf](terraform/modules/workloads/storage-account/main.tf)

## 7. Validation Checklist

Run these checks:
```bash
# No random_string/random_uuid
grep -r "random_string\|random_uuid" terraform/modules/${input:resource-type}/

# All role assignments have 'name'
grep -n "azurerm_role_assignment" terraform/modules/${input:resource-type}/ | grep -v "name ="

# No null checks in count
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/modules/${input:resource-type}/

# Terraform validation
cd terraform
terraform validate
terraform plan
```

---

## Example Usage

```
/azure storage-account implement
/azure key-vault troubleshoot "does not have secrets get permission"
/azure container-apps add-workload-profile
/azure sql debug-diagnostic-settings
```

## Variables Available
- `${input:resource-type}` - Azure resource (storage-account, key-vault, sql, container-apps)
- `${input:operation}` - Operation: implement, troubleshoot, debug, add-feature
- `${selection}` - Selected code/text in editor
- `${file}` - Current file path

## Critical Platform Stack Rules
- ❌ NEVER use random_string or random_uuid (use MD5)
- ❌ NEVER omit 'name' in azurerm_role_assignment (use uuidv5)
- ❌ NEVER skip time_sleep for RBAC (180s required)
- ❌ NEVER use != null in count (use boolean flags)
- ❌ NEVER create inter-module dependencies (orchestrate at root)
- ✅ ALWAYS validate via MCP before implementing
- ✅ ALWAYS use naming module outputs
- ✅ ALWAYS use RBAC-first security (no shared keys)
- ✅ ALWAYS add lifecycle prevent_destroy for critical resources
- ✅ ALWAYS export IDs/URIs only (never secret values)
