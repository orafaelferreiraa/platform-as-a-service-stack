# Copilot Instructions: Platform as a Service Stack - Terraform Patterns

**This file defines: Terraform code patterns, resource implementations, and dependency architecture**

---

## 🎯 When Copilot Uses This File

✅ Answering "How do I implement [resource] in this stack?"  
✅ Validating Terraform code patterns against project standards  
✅ Explaining why we use MD5 naming, uuidv5 RBAC, time_sleep delays  
✅ Recommending resource-specific configurations (Storage, SQL, Container Apps, etc)

---

## Architecture: Deterministic Naming & Dependency Layers

**Naming Convention** (non-negotiable):
- Pattern: `{name}-{location_abbr}-{md5_suffix}` for globally unique resources
- Deterministic: `substr(md5(var.name), 0, 4)` ensures same name = same suffix always (eliminates `random_string` destroy/recreate cycles)
- Location mappings: `eastus2→eus2`, `westus2→wus2`, etc in [naming/main.tf](terraform/modules/foundation/naming/main.tf)

**Why**: Random UUIDs cause destroy/recreate cycles. MD5 is stable = idempotent Terraform

**Dependency Layers** (understand before writing modules):

| Layer | Resources | Key Point |
|-------|-----------|-----------|
| **Foundation** | Resource Group (lifecycle `prevent_destroy`), Naming Convention, Managed Identity | Always Resource Group; MI optional but RECOMMENDED |
| **Networking** | VNet Spoke (default + delegated /27 subnet for Container Apps) | Independent; used by Storage/SQL/Container Apps |
| **Observability** | Log Analytics (30-day) + Application Insights (web type) | Independent; **REQUIRED for Container Apps** |
| **Workloads** | Storage, Service Bus, Event Grid, SQL Server | Use Managed Identity for RBAC (not shared keys) |
| **Security** | Key Vault (RBAC), generated SQL passwords | Key Vault waits 180s after RBAC role assignment for propagation |

## Critical Patterns & Why They Matter

### 1. RBAC-First Security (No Shared Keys)
- **Storage Account**: `shared_access_key_enabled = false` + role assignments via Managed Identity
- **Key Vault**: `rbac_authorization_enabled = true` + deterministic role names using `uuidv5()`
- **Why**: Azure AD authentication only; matches identity-based access modern Azure best practices

**Example**: [storage-account/main.tf](terraform/modules/workloads/storage-account/main.tf#L35-L40) grants Storage Blob Data Contributor via `uuidv5()` for stable role IDs.

### 2. Deterministic Role Assignment Names
```hcl
name = uuidv5("dns", "${azurerm_resource.id}-${principal_id}-{role_type}")
```
- **Why**: Replaces random IDs; ensures idempotent Terraform applies (same inputs = same role assignment ID)
- **Used in**: Key Vault, Storage Account, SQL role assignments

### 3. RBAC Propagation Delay
```hcl
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin]
  create_duration = "180s"
  triggers = { role_assignment_id = azurerm_role_assignment.current_admin.id }
}
```
- **Why**: Azure RBAC can take up to 5 minutes; ensures resources don't fail due to permission delays
- **Used in**: Key Vault, before secret creation; Storage before container creation

### 4. Feature Flag Validation
```hcl
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability' && exit 1"
  }
}
```
- **Why**: Catch impossible combinations early (e.g., Container Apps without Observability)
- **Pattern**: If a module has dependencies, validate at root [main.tf](terraform/main.tf#L11-L18)

### 5. Lifecycle: prevent_destroy on Critical Resources
Applied to: Resource Group, Key Vault, Storage Account, SQL Server
- **Why**: Accidental `terraform destroy` cannot delete these; users must delete RG in Azure Portal

## Module Structure: One Concern Per Module

Each module in `terraform/modules/{domain}/{resource}/` follows:
```
main.tf        # Resource definitions + RBAC + network rules (domain-specific)
outputs.tf     # Exports: IDs, names, principals for cross-module use
variables.tf   # Inputs: name, location, tags, role IDs, subnet IDs, flags
```

**Cross-Module Data Flow**:
- Root [main.tf](terraform/main.tf) orchestrates all modules; passes outputs as inputs
- Use explicit `depends_on` only when Terraform can't infer (e.g., role assignments before resource usage)
- **Don't**: Create inter-module dependencies; use root-level orchestration

## Workload-Specific Implementation Details

### Storage Account
- **Shared Keys Disabled**: `shared_access_key_enabled = false` + provider `storage_use_azuread = true`
- **Network Rules**: Only allow subnets from VNet if `enable_vnet=true`; defaults to public endpoint
- **RBAC Role**: Storage Blob Data Contributor assigned to Managed Identity (if `enable_managed_identity=true`)
- **Containers**: Created AFTER RBAC propagation (`depends_on = [azurerm_role_assignment...]`)
- **Blob Properties**: Versioning enabled + 7-day delete retention on blobs and containers
- **TLS**: Minimum 1.2 enforced

**Critical**: Without `storage_use_azuread = true` in provider, container creation fails with "Key based authentication is not permitted"

### SQL Server
- **Admin Username**: Hardcoded as `sql_admin` (not configurable)
- **Password**: Auto-generated via `random_password` resource (16 chars: 1 lower, 1 upper, 1 numeric, 1 special)
- **Storage**: Password stored in Key Vault as secret (if `enable_key_vault=true`)
- **AAD Admin**: Set to `data.azurerm_client_config.current.object_id` (current service principal)
- **System-Assigned Identity**: Enabled for Azure AD authentication
- **Version**: 12.0 (SQL Server 2020)
- **TLS**: Minimum 1.2 enforced
- **Firewall**: AllowAzureServices rule configured

**Critical**: Diagnostic Settings at SQL Server level do NOT support `SQLSecurityAuditEvents` or `DevOpsOperationsAudit` categories. Use only on SQL Database for these categories.

### Service Bus
- **SKU**: Premium tier (for production workloads)
- **Includes**: Default Queue and Topic resources
- **RBAC Role**: Sender/Listener assigned to Managed Identity (if enabled)
- **Network**: Public endpoint accessible (Azure Services bypass configured)

### Event Grid
- **Type**: Domain (not Topic) for flexible subscription management
- **Service Bus Integration**: Direct attributes only - **NO dynamic blocks**
  - Use `service_bus_queue_endpoint_id` and `service_bus_topic_endpoint_id` as direct attributes
  - **DO NOT** use `dynamic` blocks for these endpoints
- **RBAC**: Managed Identity as event handler principal

### Container Apps
- **HARD REQUIREMENT**: `enable_observability = true` (validation at root enforces this)
- **VNet Integration**: Optional; uses `/27 delegated subnet for `Microsoft.App/environments`
- **Workload Profile**: REQUIRED when using delegated subnet - must specify custom profile name
- **Lifecycle**: `ignore_changes = [workload_profile]` - external Kubernetes operations modify this
- **Log Analytics**: References workspace_id from Observability module
- **Internal Load Balancer**: Enabled when `infrastructure_subnet_id` provided

**Critical**: Subnet delegation to `Microsoft.App/environments` requires minimum `/27` size AND workload_profile block. Without it: `ManagedEnvironmentSubnetIsDelegated` error.

### Key Vault
- **RBAC Authorization**: MUST have `rbac_authorization_enabled = true` (non-negotiable)
- **Current Principal**: Automatically granted Key Vault Administrator via `uuidv5()` role assignment
- **RBAC Propagation**: Uses `time_sleep` with 180s delay before creating secrets
- **Soft Delete**: 7-day retention enabled
- **SKU**: Standard tier
- **Secrets**: Never expose values in outputs - export only IDs and URIs

**Critical**: Without `rbac_authorization_enabled = true`, RBAC role assignments are ignored. Azure RBAC takes 3-5 minutes to propagate - `time_sleep` is mandatory.

## Business Rules & Constraints

### Platform Identity
- **Name Input**: Only `var.name` required (lowercase alphanumeric only, validated with regex `^[a-z0-9]+$`)
- **Region**: Fixed to `eastus2` (hardcoded, not configurable via pipeline)
- **Platform Uniqueness**: Identified by `name` + `location` combination

### Feature Flag Dependencies
| Scenario | Config |
|----------|--------|
| Base infrastructure only | `enable_vnet=true`, `enable_observability=true`, all others `false` |
| Messaging only | `enable_managed_identity=true`, `enable_service_bus=true`, `enable_event_grid=true` |
| Database only | `enable_managed_identity=true`, `enable_key_vault=true`, `enable_sql=true` |
| Container Apps | `enable_observability=true` (HARD REQUIREMENT), `enable_vnet=true` (recommended) |

### Resource Lifecycle
- **prevent_destroy**: Applied to Resource Group, Key Vault, Storage Account, SQL Server
- **Implications**: Accidental `terraform destroy` cannot delete these resources; users must delete RG in Azure Portal
- **No Destroy via GitHub Actions**: Destroy workflow not available; users must manually delete RG + state file

## Developer Workflows (No GUI, CLI Only)

### Local Development Setup
1. Configure Azure Service Principal locally:
   ```bash
   # Set environment variables for Terraform
   export ARM_SUBSCRIPTION_ID="<subscription-id>"
   export ARM_TENANT_ID="<tenant-id>"
   export ARM_CLIENT_ID="<service-principal-id>"
   export ARM_CLIENT_SECRET="<service-principal-secret>"
   export ARM_USE_AZUREAD=true  # For Storage Account Azure AD auth
   ```

2. Initialize and apply:
   ```bash
   cd terraform
   terraform init \
     -backend-config="resource_group_name=rg-paas" \
     -backend-config="storage_account_name=storagepaas" \
     -backend-config="container_name=tfstate" \
     -backend-config="key=myplatform.terraform.tfstate" \
     -backend-config="use_azuread_auth=true"
   
   terraform plan -var-file=test.tfvars
   terraform apply -var-file=test.tfvars
   ```

### GitHub Actions Deployment
- **Trigger**: Actions → Deploy Platform Infrastructure workflow
- **Required Secrets**: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- **Inputs**: 
  - Platform name (lowercase alphanumeric)
  - Resource toggles (checkboxes for each `enable_*` flag)
  - Action: `plan` or `apply`
- **No Destroy Available**: To destroy: delete RG in Azure Portal + remove state file from storage account
- **Plan Review**: Manual approval required before apply

### Common Issues & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Key based authentication is not permitted" | Storage Account created with `shared_access_key_enabled=false` but provider missing `storage_use_azuread=true` | Add `storage_use_azuread = true` to provider block |
| "does not have secrets get permission on key vault" | RBAC propagation incomplete or `rbac_authorization_enabled=false` | Ensure `time_sleep` waits 180s and `rbac_authorization_enabled=true` |
| "ManagedEnvironmentSubnetIsDelegated" | Container Apps subnet delegated but no workload_profile configured | Add `workload_profile` block when using delegated subnet |
| "Container Apps requires Observability" | `enable_container_apps=true` but `enable_observability=false` | Set `enable_observability=true` (hard requirement) |
| Name already exists (rare) | MD5 suffix collision across different platform names | Change `var.name` to unique value |
| SQL diagnostic settings fails | Unsupported categories at server level | Move diagnostic settings to SQL Database level

## File References for Implementation
- **Naming logic**: [terraform/modules/foundation/naming/main.tf](terraform/modules/foundation/naming/main.tf)
- **Root orchestration**: [terraform/main.tf](terraform/main.tf)
- **Feature flags**: [terraform/variables.tf](terraform/variables.tf)
- **Example workload**: [storage-account](terraform/modules/workloads/storage-account/main.tf)
- **Documentation**: [README.md](README.md) (feature flags table), [prompt.md](prompt.md) (Portuguese design doc)

## Azure Provider 4.x Deprecated & Unsupported Patterns

**DO NOT USE** these deprecated attributes (they cause apply failures):

| Deprecated | Use Instead | Resource |
|-----------|------------|----------|
| `enable_https_traffic_only` | `https_traffic_only_enabled` | Storage Account |
| `zone_redundant` | `premium_messaging_partitions` | Service Bus |
| `enable_partitioning` | Removed - Controlled at namespace level | Service Bus Queue/Topic |
| `metric` | `enabled_metric` | Diagnostic Settings |

**UNSUPPORTED** in Provider 4.x:
- `azurerm_servicebus_namespace_network_rule_set` - Does not exist; use network rules on resources directly

**SQL Server Diagnostic Settings** - UNSUPPORTED categories:
- `SQLSecurityAuditEvents` - Only supported on SQL Database (not Server)
- `DevOpsOperationsAudit` - Only supported on SQL Database (not Server)

**Correct approach**:
```hcl
# ✅ Server-level diagnostic settings (limited categories)
resource "azurerm_monitor_diagnostic_setting" "server" {
  name                       = "sql-server-diagnostics"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "AutomaticTuning"
  }
  enabled_log {
    category = "Audit"
  }
}

# ✅ Database-level diagnostic settings (full categories)
resource "azurerm_monitor_diagnostic_setting" "database" {
  name                       = "sql-db-diagnostics"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "AutomaticTuning"
  }
  enabled_log {
    category = "Audit"
  }
  enabled_log {
    category = "SQLSecurityAuditEvents"  # Only available at Database level
  }
}
```

**Event Grid - NO Dynamic Blocks**:
```hcl
# ❌ WRONG - Dynamic blocks fail
dynamic "service_bus_queue_endpoint_id" {
  for_each = var.service_bus_queue_id != null ? [1] : []
  content {
    value = var.service_bus_queue_id
  }
}

# ✅ CORRECT - Direct attributes only
resource "azurerm_eventgrid_event_subscription" "example" {
  name                              = var.name
  scope                             = azurerm_eventgrid_domain.main.id
  service_bus_queue_endpoint_id     = var.service_bus_queue_id
  service_bus_topic_endpoint_id     = var.service_bus_topic_id
}
```

## Anti-Patterns to Avoid

### 1. Random Role Assignment Names
```hcl
# ❌ WRONG - Creates random UUID, causes destroy/recreate cycles
resource "azurerm_role_assignment" "example" {
  scope              = azurerm_resource.main.id
  role_definition_name = "Contributor"
  principal_id       = var.principal_id
  # No 'name' attribute = Azure generates random UUID
}

# ✅ CORRECT - Deterministic name with uuidv5
resource "azurerm_role_assignment" "example" {
  name                 = uuidv5("dns", "${azurerm_resource.main.id}-${var.principal_id}-contributor")
  scope                = azurerm_resource.main.id
  role_definition_name = "Contributor"
  principal_id         = var.principal_id
}
```

### 2. Conditional Count with Null Checks
```hcl
# ❌ WRONG - Causes "depends on resource attributes" error
count = var.log_analytics_workspace_id != null ? 1 : 0

# ✅ CORRECT - Use only boolean flags
count = var.enable_observability ? 1 : 0
```

### 3. Container Creation Without RBAC Delay
```hcl
# ❌ WRONG - Container created before RBAC propagates
resource "azurerm_storage_container" "data" {
  storage_account_id = azurerm_storage_account.main.id
  depends_on         = [azurerm_role_assignment.mi_blob_contributor]  # Not enough!
}

# ✅ CORRECT - Add time_sleep for RBAC propagation
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.mi_blob_contributor]
  create_duration = "180s"
  triggers = {
    role_assignment_id = azurerm_role_assignment.mi_blob_contributor.id
  }
}

resource "azurerm_storage_container" "data" {
  storage_account_id = azurerm_storage_account.main.id
  depends_on         = [time_sleep.wait_for_rbac]
}
```

### 4. Provider Configuration Without Storage Azure AD
```hcl
# ❌ WRONG - Storage Account container creation fails
provider "azurerm" {
  features {}
  # Missing storage_use_azuread = true
}

# ✅ CORRECT - Enable Azure AD for Storage operations
provider "azurerm" {
  features {}
  storage_use_azuread = true
  subscription_id     = var.subscription_id
}
```

### 5. Inter-Module Dependencies
```hcl
# ❌ WRONG - Creates tight coupling
module "storage" {
  # Directly references container apps module outputs
  vnet_subnet_ids = [module.container_apps.infrastructure_subnet_id]
}

# ✅ CORRECT - Orchestrate at root level
module "storage" {
  vnet_subnet_ids = var.enable_vnet ? [module.vnet_spoke[0].container_apps_subnet_id] : []
}
```
---

## Terraform MCP Integration (Copilot's Research Tools)

When implementing or validating Terraform patterns, copilot should use these MCPs:

### 🔎 Resource Discovery & Documentation
**When**: Copilot needs to understand resource attributes, supported configurations, or latest provider versions

```
activate_terraform_provider_documentation()
  → For SQL Server resources: 
    Query: "azurerm_mssql_server attributes, version, diagnostic settings"
    Get: Latest attributes, categories, examples
    
  → For Storage Account resources:
    Query: "azurerm_storage_account network rules, shared_access_key, azure_ad"
    Get: https_traffic_only_enabled, shared_access_key_enabled attributes
    
  → For Event Grid resources:
    Query: "azurerm_eventgrid_domain service bus integration dynamic blocks"
    Get: Confirms NO dynamic blocks supported for service_bus_*_endpoint_id
```

### 🔍 Deprecated Attribute Detection
**When**: Need to validate Terraform code doesn't use deprecated Azure Provider 4.x attributes

```
Query Pattern: "{resource} deprecated attributes azure provider 4.57"
  → Finds: enable_https_traffic_only → https_traffic_only_enabled
  → Finds: zone_redundant → premium_messaging_partitions
  → Finds: metric → enabled_metric
```

### ⚡ Provider Capabilities Check
**When**: Need to understand what a resource can do (what data sources, functions, guides available)

```
activate_terraform_provider_documentation()
mcp_hashicorp_ter_get_provider_capabilities(
  namespace: "hashicorp",
  name: "azurerm",
  version: "4.57"
)
  → Returns: Resources, data-sources, functions, guides available
```

### 📚 Module Discovery
**When**: Need to reference official Terraform modules or understand module patterns

```
mcp_hashicorp_ter_search_modules(
  query: "azure resource group",
  provider: "azure"
)
  → Returns: Official modules with descriptions, versions, documentation
```

**When to Use These MCPs**:
- ✅ Implementing new resource type (Storage, SQL, etc) → use provider_documentation
- ✅ Validating attributes aren't deprecated → use provider_documentation
- ✅ Understanding resource capabilities → use get_provider_capabilities
- ✅ Copying patterns from official modules → use search_modules

**When NOT to Use**:
- ❌ Validating anti-patterns (use instructions.instructions.md instead)
- ❌ Checking naming conventions (hardcoded in naming/main.tf)
- ❌ RBAC patterns (fixed in code examples)

---

## File References for Pattern Implementation

- **Naming logic**: [terraform/modules/foundation/naming/main.tf](terraform/modules/foundation/naming/main.tf)
- **Root orchestration**: [terraform/main.tf](terraform/main.tf)
- **Feature flags**: [terraform/variables.tf](terraform/variables.tf)
- **Example workload**: [storage-account](terraform/modules/workloads/storage-account/main.tf)
- **Documentation**: [README.md](README.md) (feature flags table), [prompt.md](prompt.md) (Portuguese design doc)