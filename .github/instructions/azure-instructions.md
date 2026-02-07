---
name: "Azure Infrastructure Best Practices - Platform as a Service Stack"
description: "Azure resource patterns, RBAC security, and PaaS-specific configurations for Platform Stack"
applyTo: "**/{main.tf,providers.tf,*.tf}"
---

# Azure Infrastructure Instructions - Platform as a Service Stack

## MCP Integration - ALWAYS Use Before Generation
**MANDATORY**: Before generating ANY Azure-related code for Platform Stack, consult these MCPs in sequence:

1. **Microsoft Documentation**:
   - `microsoft_docs_search` - Search official Azure documentation for latest patterns
   - `microsoft_code_sample_search` - Retrieve code samples (filter: `terraform`, `azurecli`)
   - `microsoft_docs_fetch` - Fetch complete documentation pages when needed

2. **Terraform Provider Validation**:
   - `mcp_hashicorp_ter_get_latest_provider_version` - Check current azurerm version
   - `mcp_hashicorp_ter_search_providers` - Search for specific Azure resources
   - `mcp_hashicorp_ter_get_provider_details` - Get complete resource schema and examples

**Pattern**: Search Microsoft docs → Get code samples → Validate with Terraform provider docs → Implement

---

## Platform Stack Architecture

### Fixed Configuration
**Region**: `eastus2` (hardcoded, not configurable)
**Location Abbreviation**: `eus2` (used in naming convention)
**Authentication**: Service Principal with Client Secret (ARM_* environment variables)
**State Backend**: Azure Blob Storage with `use_azuread_auth = true`

### Provider Configuration (MANDATORY)
```terraform
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57.0"
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

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id     = var.subscription_id
  storage_use_azuread = true  # CRITICAL for Storage Account without shared keys
}
```

**Before modifying provider**:
```bash
# Use MCP to check latest version
mcp_hashicorp_ter_get_latest_provider_version(namespace: "hashicorp", name: "azurerm")
```

---

## Azure Resource Naming Convention (DETERMINISTIC)

### Naming Pattern
**Formula**: `{name}-{location_abbr}-{md5_suffix}`
**Example**: `myapp-eus2-a1b2c3d4`

### Implementation (naming module)
```terraform
locals {
  name            = lower(var.name)
  location_abbr   = var.location == "eastus2" ? "eus2" : "wus2"
  suffix          = substr(md5(local.name), 0, 4)
  
  # Globally unique resources
  storage_account = "st${replace(local.name, "-", "")}${local.location_abbr}${local.suffix}"
  key_vault       = "kv-${local.name}-${local.location_abbr}-${local.suffix}"
  sql_server      = "sql-${local.name}-${local.location_abbr}-${local.suffix}"
  
  # Regional resources
  resource_group  = "rg-${local.name}-${local.location_abbr}"
  vnet            = "vnet-${local.name}-${local.location_abbr}"
}
```

**CRITICAL**: NEVER use `random_string` or `random_uuid` for resource names (causes destroy/recreate cycles)


---

## RBAC-First Security Model (NO SHARED KEYS)

### Core Principle
**ALL Platform Stack resources use Azure AD authentication via Managed Identity - NO shared access keys**

### Critical Configuration
```terraform
# Storage Account - RBAC only
resource "azurerm_storage_account" "main" {
  name                            = module.naming.storage_account
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = false  # MANDATORY
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
}

# Key Vault - RBAC only
resource "azurerm_key_vault" "main" {
  name                       = module.naming.key_vault
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true  # MANDATORY
  soft_delete_retention_days = 7
}
```

### RBAC Role Assignments with Deterministic Names
**CRITICAL**: Use `uuidv5()` to generate stable role assignment IDs

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
```

**Why `uuidv5()`?** Prevents destroy/recreate cycles. Azure generates random UUIDs if `name` is omitted.

### RBAC Propagation Delay (180 seconds)
**MANDATORY**: Add `time_sleep` between role assignment and dependent resource creation

```terraform
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin_kv]
  create_duration = "180s"
  
  triggers = {
    role_assignment_id = azurerm_role_assignment.current_admin_kv.id
  }
}

# Secrets created AFTER RBAC propagation
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = random_password.sql.result
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [time_sleep.wait_for_rbac]
}
```

**Common Error**: "does not have secrets get permission on key vault" → Missing `time_sleep` or `rbac_authorization_enabled = false`

---

## Azure Resource-Specific Patterns

### Storage Account
**MCP Research Before Implementation**:
```bash
microsoft_docs_search(query: "Azure Storage Account security best practices RBAC")
microsoft_code_sample_search(query: "azurerm_storage_account shared_access_key_enabled", language: "terraform")
mcp_hashicorp_ter_get_provider_details(namespace: "hashicorp", name: "azurerm", type: "azurerm_storage_account")
```

**Implementation**:
- `shared_access_key_enabled = false` (MANDATORY)
- Provider requires `storage_use_azuread = true`
- RBAC role: Storage Blob Data Contributor
- Containers created AFTER RBAC propagation
- Blob versioning + 7-day delete retention
- Network rules: Public endpoint with VNet rules (optional)

### SQL Server
**MCP Research**:
```bash
microsoft_docs_search(query: "Azure SQL Server managed identity authentication")
mcp_hashicorp_ter_get_provider_details(namespace: "hashicorp", name: "azurerm", type: "azurerm_mssql_server")
```

**Implementation**:
- Admin username: `sql_admin` (hardcoded)
- Password: Auto-generated via `random_password` (16 chars)
- Storage: Password in Key Vault as secret
- AAD Admin: Current service principal
- System-assigned identity enabled
- Version: 12.0 (SQL Server 2020)
- TLS: Minimum 1.2
- Firewall: AllowAzureServices + VNet rules
- **Diagnostic Settings**: Server-level supports LIMITED categories; use Database-level for `SQLSecurityAuditEvents`

### Key Vault
**Implementation**:
- `rbac_authorization_enabled = true` (MANDATORY)
- Current principal auto-granted Key Vault Administrator
- 180s `time_sleep` before secret creation
- Soft delete: 7-day retention
- **NEVER export secret values** in outputs (only IDs/URIs)

### Container Apps
**MCP Research**:
```bash
microsoft_docs_search(query: "Azure Container Apps managed environment VNet integration")
mcp_hashicorp_ter_get_provider_details(namespace: "hashicorp", name: "azurerm", type: "azurerm_container_app_environment")
```

**Implementation**:
- **HARD REQUIREMENT**: `enable_observability = true` (validated at root)
- VNet integration: Optional `/27` delegated subnet
- **Workload Profile**: REQUIRED when using delegated subnet
- Lifecycle: `ignore_changes = [workload_profile]` (Kubernetes modifies externally)
- Internal load balancer when `infrastructure_subnet_id` provided

---

## Feature Flag Dependencies

### Root-Level Validation
```terraform
# terraform/main.tf
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability (enable_observability=true)' && exit 1"
  }
}
```

### Dependency Matrix
| Resource | Requires (HARD) | Uses (OPTIONAL) | Feature Flag |
|----------|----------------|-----------------|--------------|
| Resource Group | - | - | Always created |
| Managed Identity | - | - | `enable_managed_identity` |
| VNet Spoke | - | - | `enable_vnet` |
| Observability | - | - | `enable_observability` |
| Storage Account | - | Managed Identity, VNet | `enable_storage` |
| Service Bus | - | Managed Identity | `enable_service_bus` |
| Event Grid | - | Managed Identity, Service Bus | `enable_event_grid` |
| SQL Server | - | Managed Identity, VNet | `enable_sql` |
| Key Vault | SQL (if enabled) | Managed Identity | `enable_key_vault` |
| Container Apps | **Observability** | VNet | `enable_container_apps` |

---

## Common Azure Errors & Solutions

### Authentication Failures
1. **Verify credentials**: `az account show`
2. **Test Service Principal**: 
   ```bash
   az login --service-principal \
     --tenant $ARM_TENANT_ID \
     --username $ARM_CLIENT_ID \
     --password $ARM_CLIENT_SECRET
   ```
3. **Check RBAC**: Ensure Contributor role on subscription
4. **Provider registration**: `az provider list --query "[?registrationState=='Registered']"`

### Storage Account Errors
- **"Key based authentication is not permitted"**: 
  - **Cause**: `shared_access_key_enabled = false` but provider missing `storage_use_azuread = true`
  - **Solution**: Add `storage_use_azuread = true` to provider block

### Key Vault Errors
- **"does not have secrets get permission on key vault"**:
  - **Cause**: RBAC not propagated OR `rbac_authorization_enabled = false`
  - **Solution**: Ensure `time_sleep` 180s + `rbac_authorization_enabled = true`

### Container Apps Errors
- **"ManagedEnvironmentSubnetIsDelegated"**:
  - **Cause**: Subnet delegated but no `workload_profile` block
  - **Solution**: Add `workload_profile` block when using delegated subnet
- **"Container Apps requires Observability"**:
  - **Cause**: `enable_container_apps=true` but `enable_observability=false`
  - **Solution**: Set `enable_observability=true` (hard requirement)

### SQL Diagnostic Settings Errors
- **"Category 'SQLSecurityAuditEvents' is not supported"**:
  - **Cause**: Using category at SQL Server level (not supported)
  - **Solution**: Move diagnostic settings to SQL Database resource

---

## New Azure Resource Implementation Process

### Step-by-Step with MCP
1. **Research with Microsoft Docs MCP**:
   ```bash
   microsoft_docs_search(query: "Azure [Resource] security best practices")
   microsoft_code_sample_search(query: "[Resource] terraform example", language: "terraform")
   microsoft_docs_fetch(url: "[specific documentation URL]")
   ```

2. **Validate Terraform Provider Support**:
   ```bash
   mcp_hashicorp_ter_search_providers(query: "azurerm [resource]")
   mcp_hashicorp_ter_get_provider_details(namespace: "hashicorp", name: "azurerm", type: "azurerm_[resource]")
   ```

3. **Check Existing Patterns in Workspace**:
   ```bash
   grep_search(query: "resource \"azurerm_[similar_resource]\"", isRegexp: false)
   semantic_search(query: "RBAC role assignment pattern")
   ```

4. **Implement with Platform Standards**:
   - Use naming module for resource names
   - RBAC-first authentication (no shared keys)
   - Deterministic `uuidv5()` for role assignments
   - 180s `time_sleep` for RBAC propagation
   - Feature flag integration
   - Lifecycle `prevent_destroy` for critical resources

5. **Validate**:
   ```bash
   terraform validate
   terraform plan
   grep -n "random_string\|random_uuid" terraform/modules/[module]/
   grep -n "azurerm_role_assignment" terraform/modules/[module]/ | grep -v "name ="
   ```

---

## Tags and Cost Management

### Mandatory Tags
```terraform
locals {
  common_tags = merge(
    var.tags,
    {
      Platform    = var.name
      ManagedBy   = "Terraform"
      Environment = var.environment
      Location    = var.location
      CreatedDate = timestamp()
    }
  )
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.location
  tags     = local.common_tags
  
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags["CreatedDate"]]
  }
}
```

### SKU Selection
- **Dev**: Standard_B2s, Basic_Gen5_2, Standard_LRS
- **Production**: Standard_D4s_v3+, GeneralPurpose_Gen5_4+, Standard_ZRS
- **High Availability**: Zone-redundant SKUs where available

**Research SKU availability**:
```bash
microsoft_docs_search(query: "Azure [Resource] SKU comparison pricing")
```

---

## Security Best Practices

### Secrets Management
**NEVER hardcode secrets** - use Key Vault:

```terraform
# Generate secret
resource "random_password" "example" {
  length  = 16
  special = true
}

# Store in Key Vault
resource "azurerm_key_vault_secret" "example" {
  name         = "example-secret"
  value        = random_password.example.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [time_sleep.wait_for_rbac]
}

# Output ONLY the secret URI (not value)
output "secret_uri" {
  value       = azurerm_key_vault_secret.example.versionless_id
  description = "Key Vault secret URI for example password"
}
```

### Network Security
- **Private Endpoints**: Production resources MUST use private endpoints
- **VNet Integration**: Optional via `enable_vnet` flag
- **Firewall Rules**: AllowAzureServices + specific VNet rules
- **TLS**: Minimum 1.2 enforced on all resources

---

## Lifecycle Management

### Prevent Accidental Deletion
```terraform
resource "azurerm_resource_group" "main" {
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_account" "main" {
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "main" {
  lifecycle {
    prevent_destroy = true
  }
}
```

**Implication**: Cannot use `terraform destroy` - must delete RG in Azure Portal manually

### Ignore External Changes
```terraform
resource "azurerm_container_app_environment" "main" {
  lifecycle {
    ignore_changes = [workload_profile]  # Kubernetes modifies externally
  }
}
```

---

## Documentation References

- **Naming Convention**: [terraform/modules/foundation/naming/main.tf](../../terraform/modules/foundation/naming/main.tf)
- **Root Orchestration**: [terraform/main.tf](../../terraform/main.tf)
- **Feature Flags**: [terraform/variables.tf](../../terraform/variables.tf)
- **Storage Pattern**: [terraform/modules/workloads/storage-account/main.tf](../../terraform/modules/workloads/storage-account/main.tf)
- **SQL Pattern**: [terraform/modules/workloads/sql/main.tf](../../terraform/modules/workloads/sql/main.tf)
- **Key Vault Pattern**: [terraform/modules/security/key-vault/main.tf](../../terraform/modules/security/key-vault/main.tf)

### Features Block Configuration
**Always include appropriate features** based on resource types:

```terraform
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false  # For automation
    }
    key_vault {
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
      recover_soft_deleted_key_vaults    = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
}
```

### Managed Identity vs Service Principal
**Preferred authentication hierarchy**:
1. **Managed Identity** (MSI) - For AKS, VMs, App Services
2. **Workload Identity** (OIDC) - For GitHub Actions, external OIDC providers
3. **Service Principal** - Last resort, requires secret management

**When generating AKS code**:
```terraform
identity {
  type = "UserAssigned"  # Preferred over SystemAssigned
  identity_ids = [azurerm_user_assigned_identity.aks.id]
}
```

---

## Network Architecture Patterns

### Private Endpoints (CRITICAL for Production)
**All data services MUST use private endpoints** in production:
- SQL Servers
- Storage Accounts
- Key Vaults
- Container Registries
- Cognitive Services

**Pattern**:
```terraform
resource "azurerm_private_endpoint" "example" {
  name                = "${var.tenant}-pe-${var.service_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.tenant}-psc-${var.service_name}"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]  # Check Microsoft docs for valid values
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}
```

### Hub-and-Spoke Network
**Reference network-stack-terraform for connectivity**:
- Firewall policies managed centrally
- IP groups define allowed sources/destinations
- VPN connectivity for on-premises

---

## Azure Cost Optimization

### Resource Tagging (MANDATORY)
**All resources MUST include these tags**:
```terraform
tags = merge(
  var.common_tags,
  {
    Environment = var.environment
    Tenant      = var.tenant
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner_email
  }
)
```

### SKU Selection Guidelines
**Consult Microsoft docs for SKU availability**:
- **Dev/QA**: Use `Standard_B2s`, `Basic_Gen5_2`, `Standard_LRS`
- **Production**: Use `Standard_D4s_v3+`, `GeneralPurpose_Gen5_4+`, `Standard_ZRS`
- **High Availability**: Enable zone redundancy where available

---

## Debugging Azure Issues

### Authentication Failures
1. **Check subscription context**: `az account show`
2. **Verify RBAC**: Ensure Service Principal has `Contributor` or specific roles
3. **Test credentials**: `az login --service-principal --tenant <tenant_id> --username <client_id> --password <client_secret>`
4. **Check provider registration**: `az provider list --query "[?registrationState=='Registered']"`

### Resource Provisioning Failures
1. **Use Microsoft docs MCP**: Search error message with #tool:mcp_microsoftdocs_microsoft_docs_search
2. **Check resource availability**: Some resources limited by region/subscription quotas
3. **Validate dependencies**: Ensure subnet, DNS zones, network security groups exist first
4. **Review Activity Log**: Use Azure Portal → Monitor → Activity Log

### Common Error Solutions
- **"QuotaExceeded"**: Request quota increase via Azure Portal
- **"ResourceGroupNotFound"**: Create RG first or check provider alias
- **"SubnetIsFull"**: Expand subnet CIDR or create new subnet
- **"SkuNotAvailable"**: Check region availability with #tool:mcp_microsoftdocs_microsoft_docs_search

---

## New Feature Implementation

### Process for Adding Azure Resources
1. **Research with MCP**:
   - #tool:mcp_microsoftdocs_microsoft_docs_search → Find resource overview
   - #tool:mcp_microsoftdocs_microsoft_docs_fetch → Get complete page for specific resource
   - #tool:mcp_microsoftdocs_microsoft_code_sample_search → Retrieve Terraform examples

2. **Validate provider support**:
   - #tool:mcp_hashicorp_ter_search_providers → Search for resource type
   - #tool:mcp_hashicorp_ter_get_provider_details → Get full resource schema

3. **Check existing patterns**:
   - Search workspace for similar resources: #tool:grep_search
   - Review terraform-azurerm-* modules for reusable patterns

4. **Implement with standards**:
   - Use multi-subscription provider pattern
   - Apply naming conventions
   - Add tags
   - Include private endpoints if applicable
   - Pin provider version

5. **Test and validate**:
   - Run `terraform validate`
   - Use `terraform plan` with correct tfvars
   - Review plan output for unintended changes

---

## Security Best Practices

### Secrets Management
**NEVER hardcode secrets** - use Azure Key Vault:
```terraform
data "azurerm_key_vault_secret" "example" {
  provider     = azurerm.stefanininam
  name         = "connection-string"
  key_vault_id = var.key_vault_id
}

# Reference as: data.azurerm_key_vault_secret.example.value
```

### Network Security
1. **Default deny**: Use Network Security Groups with explicit allow rules
2. **Private networking**: Deploy resources in VNets with private IPs
3. **Service endpoints**: Enable for Azure PaaS services (SQL, Storage)
4. **Check firewall rules**: Review network-stack-terraform/ip_groups.tf before adding resources

### RBAC Assignments
**Use least privilege principle**:
```terraform
resource "azurerm_role_assignment" "example" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"  # Not "Owner" unless required
  principal_id         = var.service_principal_id
}
```

---

## Azure-Specific Modules

### Using terraform-azurerm-* Modules
**Reusable modules in workspace**:
- `terraform-azurerm-storage` - Storage accounts with networking
- `terraform-azurerm-postgresql-flexible-server` - PostgreSQL DBaaS
- `terraform-azurerm-sqluser` - SQL authentication with Key Vault integration
- `terraform-azurerm-sso` - Azure AD SSO configuration

**Module usage pattern**:
```terraform
module "storage" {
  source = "../terraform-azurerm-storage"

  provider_alias      = azurerm.stefanininam
  storage_account_name = "na-st-data-prod"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Network configuration
  network_rules = {
    default_action = "Deny"
    ip_rules       = var.allowed_ips
    virtual_network_subnet_ids = [var.subnet_id]
  }
}
```

---

## Performance and Reliability

### Azure Regions
**Primary regions** (in order of preference):
1. `East US` - Primary for NA tenant
2. `West Europe` - Primary for EMEA tenant
3. `Brazil South` - LATAM tenant

**Pairing for disaster recovery**:
- East US ↔ West US
- West Europe ↔ North Europe

### Auto-scaling Configuration
**For AKS node pools**:
```terraform
auto_scaler_profile {
  max_graceful_termination_sec = 600
  scale_down_delay_after_add   = "10m"
  scale_down_unneeded          = "10m"

  max_node_provisioning_time   = "15m"
  skip_nodes_with_system_pods  = true
}
```

---

## Final Checklist for Azure Code

Before submitting Azure infrastructure code:
- [ ] MCP tools consulted (Microsoft docs + Terraform provider docs)
- [ ] Provider version pinned with `~>`
- [ ] Multi-subscription provider alias used
- [ ] Naming convention followed (`<tenant>-<resource>-<env>`)
- [ ] Tags applied (Environment, Tenant, ManagedBy, Owner)
- [ ] Private endpoints for data services
- [ ] Secrets in Key Vault (not hardcoded)
- [ ] RBAC with least privilege
- [ ] Network security rules reviewed
- [ ] Region and SKU validated
- [ ] `terraform validate` passed
- [ ] Backend configuration verified
