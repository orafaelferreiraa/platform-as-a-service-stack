---
applyTo: '**'
---

# AI Coding Guidelines: Platform as a Service Stack

**This file defines: Hard-coded rules that NEVER change. Static reference for code validation.**

When to use: During code review, validation checklist, anti-pattern detection, error troubleshooting.

---

## Non-Negotiable Rules

## Non-Negotiable Rules

### 1. Region & Location
- ✅ ALWAYS `eastus2` (hardcoded in [variables.tf](terraform/variables.tf#L18))
- ✅ Location abbreviation: `eastus2→eus2` in [naming/main.tf](terraform/modules/foundation/naming/main.tf)
- ❌ NEVER configurable via Terraform variables or pipeline inputs

### 2. Naming Convention
- ✅ Pattern: `{name}-{location_abbr}-{md5_suffix}`
- ✅ Example: `myapp-eus2-a1b2c3d4`
- ✅ Formula: `suffix = substr(md5(var.name), 0, 4)`
- ❌ NEVER use `random_string` (causes destroy/recreate cycles)
- ❌ NEVER use `random_uuid` for resource names
- **Scan**: `grep -r "random_string\|random_uuid" terraform/modules/` to find violations

### 3. RBAC Role Assignments
- ✅ ALWAYS deterministic name: `name = uuidv5("dns", "${scope}-${principal}-{role_type}")`
- ✅ Example: `uuidv5("dns", "${azurerm_storage_account.main.id}-${var.managed_identity_principal_id}-blob-contributor")`
- ❌ NEVER omit `name` attribute (Azure generates random UUID on every apply)
- ❌ NEVER use conditional assignment creation (`count = var.x != null ? 1 : 0`)
- **Scan**: `grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="` to find violations

### 4. RBAC Propagation Delay (180 seconds)
- ✅ ALWAYS add `time_sleep` between role assignment and secret/container creation:
  ```hcl
  resource "time_sleep" "wait_for_rbac" {
    depends_on      = [azurerm_role_assignment.example]
    create_duration = "180s"
    triggers = { role_assignment_id = azurerm_role_assignment.example.id }
  }
  ```
- ✅ ALWAYS use `depends_on = [time_sleep.wait_for_rbac]` on dependent resources
- ❌ NEVER rely on `depends_on = [azurerm_role_assignment...]` alone
- **Error Pattern**: "does not have secrets get permission on key vault" → Missing time_sleep

### 5. Count Conditions (Boolean ONLY)
- ✅ CORRECT: `count = var.enable_observability ? 1 : 0`
- ❌ WRONG: `count = var.log_analytics_workspace_id != null ? 1 : 0`
- ❌ WRONG: `count = var.some_id != "" ? 1 : 0`
- **Why**: Null/empty checks cause "depends on resource attributes" errors
- **Scan**: `grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/` to find violations

### 6. Module Dependencies
- ✅ Root-level orchestration ONLY in [terraform/main.tf](terraform/main.tf)
- ✅ Module-to-module data flow via root variables (NO direct module refs)
- ❌ NEVER: `module.storage.vnet_subnet_ids = module.vnet.subnet_id`
- ✅ CORRECT: `module.storage.vnet_subnet_ids = var.enable_vnet ? [module.vnet[0].subnet_id] : []`
- **Pattern**: If a module needs output from another, pass via [main.tf](terraform/main.tf) orchestration

### 7. Feature Flag Integration
- ✅ ALWAYS use `enable_*` boolean variables in [terraform/variables.tf](terraform/variables.tf)
- ✅ ALWAYS add validation at root for hard dependencies (e.g., "Container Apps requires Observability")
- ✅ ALWAYS use `count = var.enable_* ? 1 : 0` in module calls
- ❌ NEVER use `optional()` type without explicit defaults
- **Reference**: [terraform/main.tf](terraform/main.tf) validation blocks for pattern

### 8. Outputs (NO Secrets)
- ✅ Export only: Resource IDs, URIs, names, principals
- ✅ Example: `id`, `endpoint`, `fqdn`, `principal_id`, `secret_uri`
- ❌ NEVER: Export secret values, passwords, connection strings with credentials
- ❌ NEVER: `output "admin_password" { value = random_password.sql.result }`
- ✅ CORRECT: `output "secret_uri" { value = azurerm_key_vault_secret.sql_password.versionless_id }`

---

## Dependency Layers

```
Layer 1 (Foundation - no dependencies)
  ├─ Resource Group (prevent_destroy=true, always created)
  ├─ Naming Convention (MD5-based suffixes)
  ├─ Managed Identity (optional but RECOMMENDED)
  ├─ VNet Spoke (optional)
  └─ Observability (Log Analytics 30-day + App Insights)

Layer 2 (Workloads - optional dependencies)
  ├─ Storage Account (uses: MI for RBAC, VNet for rules)
  ├─ Service Bus Premium (uses: MI for RBAC)
  ├─ Event Grid Domain (uses: MI for RBAC, Service Bus for subs)
  ├─ SQL Server (uses: MI for RBAC, VNet for firewall)
  └─ Key Vault RBAC (uses: MI for RBAC, stores SQL password)

Layer 3 (Compute - hard requirements)
  └─ Container Apps (REQUIRES: Observability; uses: VNet with /27 delegated subnet)
```

**Rule**: Root [main.tf](terraform/main.tf) orchestrates all modules. DO NOT create inter-module dependencies.

---

## Critical Patterns

### 1. RBAC with Deterministic Role Assignment Names
```hcl
# ✅ CORRECT - Deterministic uuidv5
name = uuidv5("dns", "${resource_id}-${principal_id}-{role_type}")

# ❌ WRONG - Random UUID causes destroy/recreate
# (omit 'name' and Azure generates random UUID)
```

### 2. RBAC Propagation Delay
```hcl
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin]
  create_duration = "180s"
  triggers = { role_assignment_id = azurerm_role_assignment.current_admin.id }
}
# Secrets created AFTER this time_sleep
```

### 3. Feature Flag Validation (Root Level)
```hcl
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability' && exit 1"
  }
}
```

### 4. Count Conditions (Boolean Only, Never Null Checks)
```hcl
# ✅ CORRECT - Boolean deterministic
count = var.enable_observability ? 1 : 0

# ❌ WRONG - "depends on resource attributes" error
count = var.log_analytics_workspace_id != null ? 1 : 0
```

### 5. Storage Azure AD Auth (Provider + Config)
```hcl
provider "azurerm" {
  features {}
  storage_use_azuread = true  # MANDATORY when shared_access_key_enabled=false
}

resource "azurerm_storage_account" "main" {
  shared_access_key_enabled = false  # Azure AD only
}
```

---

## Resource-Specific Implementation

### Storage Account
- **Shared Keys**: ALWAYS disabled (`shared_access_key_enabled = false`)
- **Azure AD**: Provider requires `storage_use_azuread = true`
- **RBAC Role**: Storage Blob Data Contributor via Managed Identity
- **Containers**: Created AFTER RBAC propagation with `depends_on = [time_sleep.wait_for_rbac]`
- **Blob Properties**: Versioning + 7-day delete retention on blobs AND containers
- **Network**: Public endpoint (VNet rules optional via `vnet_subnet_ids`)
- **TLS**: Minimum 1.2 enforced

### SQL Server
- **Admin Username**: Hardcoded `sql_admin` (NOT configurable)
- **Password**: Auto-generated 16-char random (1 lower, 1 upper, 1 numeric, 1 special)
- **Storage**: Password stored in Key Vault as secret (if `enable_key_vault=true`)
- **AAD Admin**: Set to `data.azurerm_client_config.current.object_id`
- **System Identity**: Enabled for Azure AD auth
- **Version**: 12.0 (SQL Server 2020)
- **TLS**: Minimum 1.2
- **Firewall**: AllowAzureServices rule + VNet rules if enabled
- **Diagnostic Settings**: Server-level only supports limited categories; use SQL Database level for `SQLSecurityAuditEvents`, `DevOpsOperationsAudit`

### Service Bus
- **SKU**: Premium tier (production requirement)
- **Includes**: Default Queue and Topic
- **RBAC Role**: Managed Identity for Sender/Listener roles
- **Network**: Public endpoint (Azure Services bypass configured)

### Event Grid
- **Type**: Domain (NOT Topic) for flexible subscription management
- **Service Bus Integration**: Use DIRECT attributes ONLY
  ```hcl
  service_bus_queue_endpoint_id = var.service_bus_queue_id      # Direct attribute
  service_bus_topic_endpoint_id = var.service_bus_topic_id      # Direct attribute
  # ❌ DO NOT use dynamic blocks for these
  ```

### Container Apps
- **HARD REQUIREMENT**: `enable_observability = true` (enforced at root)
- **VNet Integration**: Optional; uses `/27 delegated subnet for `Microsoft.App/environments`
- **Workload Profile**: REQUIRED when using delegated subnet (custom profile name)
- **Lifecycle**: `ignore_changes = [workload_profile]` (Kubernetes modifies externally)
- **Log Analytics**: References `workspace_id` from Observability module
- **Subnet Delegation**: Minimum `/27` size AND workload_profile block; omitting either causes `ManagedEnvironmentSubnetIsDelegated` error

### Key Vault
- **RBAC Authorization**: MUST have `rbac_authorization_enabled = true` (non-negotiable)
- **Current Principal**: Automatically granted Key Vault Administrator via uuidv5
- **RBAC Propagation**: Uses `time_sleep` with 180s delay before secret creation
- **Soft Delete**: 7-day retention enabled
- **SKU**: Standard tier
- **Secrets**: NEVER expose values in outputs (only IDs and URIs)

---

## Feature Flag Scenarios

| Scenario | Config |
|----------|--------|
| **Base Infrastructure** | `enable_vnet=true`, `enable_observability=true`, all others `false` |
| **Messaging Only** | `enable_managed_identity=true`, `enable_service_bus=true`, `enable_event_grid=true` |
| **Database Only** | `enable_managed_identity=true`, `enable_key_vault=true`, `enable_sql=true` |
| **Container Apps** | `enable_observability=true` (HARD REQUIREMENT), `enable_vnet=true` (recommended) |

---

## Developer Workflows

### Local Setup
```bash
# 1. Environment variables
export ARM_SUBSCRIPTION_ID="<id>"
export ARM_TENANT_ID="<id>"
export ARM_CLIENT_ID="<id>"
export ARM_CLIENT_SECRET="<secret>"
export ARM_USE_AZUREAD=true

# 2. Initialize with backend config
cd terraform
terraform init \
  -backend-config="resource_group_name=rg-paas" \
  -backend-config="storage_account_name=storagepaas" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=myplatform.terraform.tfstate" \
  -backend-config="use_azuread_auth=true"

# 3. Plan and apply
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```

### GitHub Actions Deployment
- **Trigger**: Actions → Deploy Platform Infrastructure workflow
- **Inputs**: Platform name (lowercase alphanumeric), resource toggles, action (`plan` or `apply`)
- **Secrets Required**: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- **No Destroy**: Delete RG in portal + remove state file manually
- **Plan Review**: Manual approval required before apply

---

## Azure Provider 4.x Gotchas

### Deprecated Attributes (NEVER USE)
| Old | New | Resource |
|-----|-----|----------|
| `enable_https_traffic_only` | `https_traffic_only_enabled` | Storage Account |
| `zone_redundant` | `premium_messaging_partitions` | Service Bus |
| `enable_partitioning` | Removed (namespace-level control) | Service Bus Queue/Topic |
| `metric` | `enabled_metric` | Diagnostic Settings |

### Unsupported Resources
- `azurerm_servicebus_namespace_network_rule_set` does not exist (use direct network rules on resources)

### SQL Diagnostic Settings (Server vs Database)
```hcl
# ✅ Server-level: Limited categories (AutomaticTuning, Audit, etc)
resource "azurerm_monitor_diagnostic_setting" "server" {
  target_resource_id = azurerm_mssql_server.main.id
  enabled_log { category = "Audit" }
}

# ✅ Database-level: Full categories (includes SQLSecurityAuditEvents, DevOpsOperationsAudit)
resource "azurerm_monitor_diagnostic_setting" "database" {
  target_resource_id = azurerm_mssql_database.main.id
  enabled_log { category = "SQLSecurityAuditEvents" }  # Database-level only
}
```

---

## Anti-Patterns (DO NOT DO)

### 1. Random Role Assignment Names
```hcl
# ❌ WRONG - Destroy/recreate every apply
resource "azurerm_role_assignment" "example" {
  scope = azurerm_resource.main.id
  # Omitting 'name' = Azure generates random UUID
}

# ✅ CORRECT
resource "azurerm_role_assignment" "example" {
  name = uuidv5("dns", "${azurerm_resource.main.id}-${var.principal_id}-role")
  scope = azurerm_resource.main.id
}
```

### 2. Container Creation Before RBAC Delay
```hcl
# ❌ WRONG - depends_on alone insufficient for RBAC propagation
resource "azurerm_storage_container" "data" {
  storage_account_id = azurerm_storage_account.main.id
  depends_on = [azurerm_role_assignment.mi_blob_contributor]
}

# ✅ CORRECT
resource "time_sleep" "wait_for_rbac" {
  depends_on = [azurerm_role_assignment.mi_blob_contributor]
  create_duration = "180s"
  triggers = { role_assignment_id = azurerm_role_assignment.mi_blob_contributor.id }
}
resource "azurerm_storage_container" "data" {
  storage_account_id = azurerm_storage_account.main.id
  depends_on = [time_sleep.wait_for_rbac]
}
```

### 3. Provider Without Storage Azure AD
```hcl
# ❌ WRONG - "Key based authentication is not permitted" error
provider "azurerm" {
  features {}
  # Missing storage_use_azuread = true
}

# ✅ CORRECT
provider "azurerm" {
  features {}
  storage_use_azuread = true
}
```

### 4. Event Grid with Dynamic Blocks
```hcl
# ❌ WRONG - Dynamic blocks not supported for these attributes
dynamic "service_bus_queue_endpoint_id" {
  for_each = var.service_bus_queue_id != null ? [1] : []
  content { value = var.service_bus_queue_id }
}

# ✅ CORRECT - Direct attributes
service_bus_queue_endpoint_id = var.service_bus_queue_id
service_bus_topic_endpoint_id = var.service_bus_topic_id
```

### 5. Inter-Module Dependencies
```hcl
# ❌ WRONG - Tight coupling between modules
module "storage" {
  vnet_subnet_ids = [module.container_apps.infrastructure_subnet_id]
}

# ✅ CORRECT - Orchestrate at root level
module "storage" {
  vnet_subnet_ids = var.enable_vnet ? [module.vnet_spoke[0].container_apps_subnet_id] : []
}
```

---

## Common Issues & Solutions

| Error | Cause | Fix |
|-------|-------|-----|
| "Key based authentication is not permitted" | Provider missing `storage_use_azuread = true` | Add to provider block |
| "does not have secrets get permission on key vault" | RBAC not propagated or `rbac_authorization_enabled=false` | Use `time_sleep` 180s + verify `rbac_authorization_enabled=true` |
| "ManagedEnvironmentSubnetIsDelegated" | Container Apps subnet delegated but no `workload_profile` | Add `workload_profile` block when using delegated subnet |
| "Container Apps requires Observability" | `enable_container_apps=true` but `enable_observability=false` | Set `enable_observability=true` |
| "Name already exists" | MD5 suffix collision (extremely rare) | Change `var.name` to unique value |
| SQL diagnostic settings fails | Unsupported category at server level | Move settings to SQL Database level |

---

## Key File References

- **Naming Logic**: [terraform/modules/foundation/naming/main.tf](terraform/modules/foundation/naming/main.tf)
- **Root Orchestration**: [terraform/main.tf](terraform/main.tf)
- **Feature Flags**: [terraform/variables.tf](terraform/variables.tf)
- **Storage Example**: [terraform/modules/workloads/storage-account/main.tf](terraform/modules/workloads/storage-account/main.tf)
- **SQL Example**: [terraform/modules/workloads/sql/main.tf](terraform/modules/workloads/sql/main.tf)
- **Key Vault Example**: [terraform/modules/security/key-vault/main.tf](terraform/modules/security/key-vault/main.tf)
- **Configuration Matrix**: [README.md](README.md) (feature flags, usage examples)
- **Design Document**: [prompt.md](prompt.md) (Portuguese architecture details)

---

## Validation Checklist (Use Before Commit)

Run these commands to ensure no violations:

```bash
# Rule 2: No random_string or random_uuid in resource names
grep -r "random_string\|random_uuid" terraform/modules/ 

# Rule 3: All role assignments have deterministic names
grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="

# Rule 5: No null checks in count conditions
grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/

# Rule 6: No inter-module dependencies
grep -n "module\\..*\\..*=" terraform/modules/ | grep -v "# This is OK"

# Syntax validation
cd terraform
terraform validate
```

**If ANY commands return results (except terraform validate ✓), fix immediately before committing.**

---

## Consulting Official Docs (Required for New Resources)

When implementing NEW features, consult Terraform Provider Docs:

- **Terraform Registry**: [azurerm provider v4.57+](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) - Official resource attributes
- **Azure Docs**: [Resource naming and tagging conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) - Naming best practices

