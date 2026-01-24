---
agent: agent
---

# Platform as a Service Stack - Operational Procedures with MCPs

**This file defines: Step-by-step procedures with exact MCP queries and expected outputs**

---

## Project Context

**Azure Platform as a Service Stack v3.0.0+** - Modular Terraform infrastructure for Azure.

### Key Facts
- **Region**: Fixed `eastus2` | **Orchestration**: Root [main.tf](terraform/main.tf) only  
- **Naming**: Deterministic MD5 (`substr(md5(var.name), 0, 4)`) - NEVER `random_string`
- **RBAC**: Deterministic `uuidv5("dns", "${scope}-${principal}-{role}")` - NEVER random IDs
- **Propagation**: 180s `time_sleep` REQUIRED between role assignment and secret/container creation

---

## Procedure 1: Implement New Infrastructure Module

**Scenario**: Add Redis Cache, Cosmos DB, or similar workload resource

**Step 1 - Research Resource Attributes (MCP)**
```
activate_terraform_provider_documentation()
mcp_hashicorp_ter_get_provider_details(
  query: "azurerm_redis_cache required attributes, RBAC, network rules"
)
Expected Output: Attributes list, example configurations, deprecated warnings
```

**Step 2 - Find Similar Module Pattern**
```bash
grep_search(
  query: "resource \"azurerm_storage_account",
  includePattern: "terraform/modules/workloads/storage-account/*"
)
Purpose: Understand module structure (main.tf pattern with RBAC + network rules)
```

**Step 3 - Create Module Files**
```
terraform/modules/workloads/redis/
  ├── main.tf       (resource + RBAC + network rules)
  ├── outputs.tf    (IDs only, NO secrets)
  └── variables.tf  (consistent inputs)

Reference Patterns:
  → Naming: substr(md5(var.name), 0, 4) from naming/main.tf
  → RBAC: uuidv5 pattern from storage-account/main.tf
  → time_sleep: 180s delay before creating secrets
```

**Step 4 - Add Feature Flag**
```hcl
# terraform/variables.tf
variable "enable_redis" {
  type = bool
  default = true
  description = "Enable Redis Cache"
}

# terraform/main.tf
module "redis" {
  count  = var.enable_redis ? 1 : 0
  source = "./modules/workloads/redis"
  ...
}
```

**Step 5 - Validate**
```bash
terraform validate        # Must pass
terraform plan            # Check for dependency errors
grep -n "random_string" terraform/modules/redis/  # Should be empty
```

**Success Criteria**: ✅ Module follows single-concern | ✅ All role assignments use uuidv5 | ✅ No `random_string`

---

## Procedure 2: Fix RBAC Propagation Timeout ("does not have permission")

**Root Cause**: RBAC takes 3-5 minutes to propagate; secrets created too early

**Step 1 - Locate Problem**
```bash
grep_search(
  query: "azurerm_key_vault_secret|azurerm_storage_container",
  includePattern: "terraform/modules/security/key-vault/*"
)
Find: Resource creation immediately after role assignment (missing time_sleep)
```

**Step 2 - Add time_sleep Block**
```hcl
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin]
  create_duration = "180s"
  triggers = {
    role_assignment_id = azurerm_role_assignment.current_admin.id
  }
}
```

**Step 3 - Update Dependent Resources**
```hcl
resource "azurerm_key_vault_secret" "example" {
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [time_sleep.wait_for_rbac]  # ADD THIS
  ...
}
```

**Step 4 - Validate**
```bash
terraform validate && terraform plan
```

**Success Criteria**: ✅ 180s time_sleep added | ✅ All secrets/containers have `depends_on = [time_sleep...]` | ✅ No RBAC errors

---

## Procedure 3: Fix Azure Provider 4.x Deprecated Attributes

**Deprecated Mappings**:
| Old | New | Resource |
|-----|-----|----------|
| `enable_https_traffic_only` | `https_traffic_only_enabled` | Storage |
| `zone_redundant` | `premium_messaging_partitions` | Service Bus |
| `metric` | `enabled_metric` | Diagnostic Settings |

**Step 1 - Find Deprecated Attributes (MCP)**
```bash
grep_search(
  query: "enable_https_traffic_only|zone_redundant|metric",
  includePattern: "terraform/**/*.tf"
)
Expected Output: List of deprecated attributes with locations
```

**Step 2 - Verify Correct Replacements (MCP)**
```
activate_terraform_provider_documentation()
Query: "azure provider 4.57 deprecated attributes"
Expected Output: Mapping of all deprecated → new attributes
```

**Step 3 - Replace All Occurrences**
```bash
# Example: Storage Account
enable_https_traffic_only = true  →  https_traffic_only_enabled = true
```

**Step 4 - Validate**
```bash
terraform validate  # No deprecation warnings
```

**Success Criteria**: ✅ No deprecated attributes remain | ✅ terraform validate passes

---

## Procedure 4: SQL Diagnostic Settings (Correct Categories)

**Key Rule**: SQL Server-level does NOT support `SQLSecurityAuditEvents`, `DevOpsOperationsAudit` → use Database level

**Step 1 - Research Supported Categories (MCP)**
```
activate_terraform_provider_documentation()
Query: "azurerm_mssql_server diagnostic settings supported categories"
Query: "azurerm_mssql_database diagnostic settings supported categories"
Expected: Server-level is LIMITED | Database-level is FULL (includes SQLSecurityAuditEvents)
```

**Step 2 - Implement Server-Level Settings**
```hcl
resource "azurerm_monitor_diagnostic_setting" "server" {
  name                       = "${var.name}-server-diag"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log { category = "Audit" }
  enabled_log { category = "AutomaticTuning" }
}
```

**Step 3 - Implement Database-Level Settings**
```hcl
resource "azurerm_monitor_diagnostic_setting" "database" {
  name                       = "${var.name}-db-diag"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log { category = "SQLSecurityAuditEvents" }    # Database-level only
  enabled_log { category = "DevOpsOperationsAudit" }     # Database-level only
}
```

**Step 4 - Validate**
```bash
terraform validate && terraform plan
```

**Success Criteria**: ✅ Server-level: LIMITED categories | ✅ Database-level: FULL categories | ✅ terraform passes

---

## Procedure 5: Container Apps VNet + Workload Profile

**Hard Requirements**:
1. `enable_observability = true` (validation at root)
2. `/27 minimum subnet size`
3. `workload_profile` block when using delegated subnet

**Step 1 - Add Validation at Root**
```hcl
# terraform/main.tf
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability' && exit 1"
  }
}
```

**Step 2 - Create Delegated Subnet in VNet Module**
```hcl
resource "azurerm_subnet" "container_apps" {
  count               = var.enable_container_apps ? 1 : 0
  name                = "${var.name}-ca-subnet"
  address_prefixes    = ["10.0.2.0/27"]  # /27 minimum
  
  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}
```

**Step 3 - Create Container Apps Environment**
```hcl
resource "azurerm_container_app_environment" "main" {
  name                           = "${var.name}-cae"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  log_analytics_workspace_id      = var.log_analytics_workspace_id  # From observability
  infrastructure_subnet_id        = var.infrastructure_subnet_id     # From VNet
  
  workload_profile {
    name             = "consumption"
    workload_profile_type = "Consumption"
  }
  
  ignore_changes = [workload_profile]  # Kubernetes modifies externally
}
```

**Step 4 - Validate Dependencies**
```bash
grep "enable_observability = true" terraform/variables.tf
grep "/27" terraform/modules/networking/vnet-spoke/main.tf
grep "workload_profile" terraform/modules/workloads/container-apps/main.tf
```

**Success Criteria**: ✅ enable_observability validation enforced | ✅ /27 subnet | ✅ workload_profile block exists | ✅ No "ManagedEnvironmentSubnetIsDelegated" error

---

## Procedure 6: Code Review - Detect & Fix Anti-Patterns

**Use grep to Find Issues**:

```bash
# Anti-pattern 1: Missing 'name' in role assignment (random UUID)
grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="
# Expected: Empty (no results)

# Anti-pattern 2: Null checks in count conditions
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/
# Expected: Empty (no results)

# Anti-pattern 3: Missing time_sleep before containers/secrets
grep -B 5 "azurerm_storage_container\|azurerm_key_vault_secret" terraform/modules -r | grep -v "time_sleep"
# Expected: time_sleep block appears before creation

# Anti-pattern 4: Dynamic blocks in Event Grid
grep -n "dynamic " terraform/modules/workloads/event-grid/ | grep "service_bus"
# Expected: Empty (no dynamic blocks for service_bus_*_endpoint_id)

# Anti-pattern 5: Inter-module dependencies
grep -n "module\\..*\\..*=" terraform/modules/ 
# Expected: Empty (no module references in modules directory)
```

**For Each Issue**:
1. Identify line number and file
2. Apply correct pattern from [instructions.instructions.md](instructions.instructions.md)
3. Validate with `terraform validate`

**Success Criteria**: ✅ All grep commands return empty | ✅ terraform validate passes | ✅ Follows [instructions.md](instructions.instructions.md)

---

## MCP Integration Reference

| Procedure | MCP | Query |
|-----------|-----|-------|
| **Implement Module** | `activate_terraform_provider_documentation()` | "azurerm_{resource} attributes RBAC network" |
| **Fix RBAC Timeout** | `grep_search()` | Find role_assignment without time_sleep |
| **Fix Deprecated** | `activate_terraform_provider_documentation()` | "deprecated azure provider 4.57" |
| **SQL Diagnostics** | `activate_terraform_provider_documentation()` | "azurerm_mssql_database categories" |
| **Container Apps** | `grep_search()` | Search subnet delegation + workload_profile |
| **Code Review** | `grep_search()` | Anti-pattern grep commands above |

---

## Operational Guidelines

### Before Starting Work
1. Read [instructions.instructions.md](.github/instructions/instructions.md) - all hard rules
2. Review [main.tf](terraform/main.tf) - orchestration pattern
3. Check [variables.tf](terraform/variables.tf) - feature flags
4. Scan relevant module - understand existing structure

### During Implementation
- Use existing modules as templates
- Run `terraform validate` after each change
- Check `terraform plan` for dependency errors
- Verify outputs don't expose secrets

### Validation Checklist
- [ ] Naming uses MD5 deterministic suffix
- [ ] All role assignments use uuidv5
- [ ] Feature flag added to variables.tf
- [ ] Module called in main.tf with count condition
- [ ] RBAC propagation time_sleep present
- [ ] No inter-module dependencies
- [ ] No deprecated Azure attributes
- [ ] terraform validate passes

---

## Key File References

| File | Purpose |
|------|---------|
| [terraform/main.tf](terraform/main.tf) | Root orchestration - only place for module interdependencies |
| [terraform/variables.tf](terraform/variables.tf) | All feature flags defined |
| [terraform/modules/foundation/naming/main.tf](terraform/modules/foundation/naming/main.tf) | MD5 naming convention |
| [terraform/modules/security/key-vault/main.tf](terraform/modules/security/key-vault/main.tf) | RBAC + time_sleep pattern |
| [terraform/modules/workloads/storage-account/main.tf](terraform/modules/workloads/storage-account/main.tf) | Azure AD + RBAC + containers pattern |
| [terraform/modules/workloads/sql/main.tf](terraform/modules/workloads/sql/main.tf) | SQL password + diagnostic settings |
| [.github/instructions/instructions.md](.github/instructions/instructions.md) | Coding guidelines |
| [README.md](README.md) | Feature flags, business rules |

