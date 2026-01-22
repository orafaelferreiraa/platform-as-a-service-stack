# Platform as a Service Stack

Azure infrastructure platform for accelerating product development through composable, secure, and reusable infrastructure capabilities.

> **Version 3.0.0**: Full implementation with deterministic naming conventions (MD5 suffixes), RBAC-enabled security, and comprehensive feature flags.

---

## 📋 What's New in v3.0

### Core Implementation
- ✅ **Deterministic Naming**: MD5-based suffixes for globally unique resource names (no `random_string` destroy/recreate cycles)
- ✅ **RBAC-First Security**: All resources use Azure AD authentication and role-based access
- ✅ **Feature Flags**: All resources optional via `enable_*` variables with proper dependency validation
- ✅ **Time-based RBAC Propagation**: 180s `time_sleep` before creating secrets to ensure Azure AD RBAC propagation
- ✅ **Deterministic Role Assignments**: All role assignments use `uuidv5()` for stable IDs across applies
- ✅ **Complete Observability**: Diagnostic settings integrated when Observability is enabled

### Key Resources Implemented
- **Foundation**: Resource Group (with `prevent_destroy`), Naming Convention, Managed Identity
- **Networking**: VNet Spoke with default + delegated subnets for Container Apps
- **Security**: Key Vault (RBAC-enabled), Managed Identity
- **Workloads**: Storage Account (Azure AD only), Service Bus (Premium), Event Grid, SQL Server (AAD admin), Observability, Container Apps

---

## Quick Start

### 1. Prerequisites

- Azure Subscription
- Terraform 1.9.0+
- GitHub repository with Actions enabled
- Azure Service Principal with appropriate permissions

### 2. Configure GitHub Secrets

Add the following secrets to your repository:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### 3. Provision Infrastructure

#### Via GitHub Actions (Recommended)
1. Go to **Actions** → **Deploy Platform Infrastructure**
2. Click **Run workflow**
3. Fill in the platform name (lowercase alphanumeric only)
4. Select resources to provision using feature flag checkboxes
5. Choose action: `plan` or `apply`
6. Review the plan and approve

> **Note**: Destroy is not available via workflow. To destroy resources, delete the Resource Group in Azure Portal and remove the state file from the storage account.

#### Via Terraform CLI (Local Development)
```bash
cd terraform
terraform init \
  -backend-config="resource_group_name=rg-paas" \
  -backend-config="storage_account_name=storagepaas" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=myplatform.terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform plan
terraform apply
```

---

## Feature Flags

All resources are controlled via boolean feature flags. Enable only what you need:

| Flag | Resource | Default | Dependencies |
|------|----------|---------|--------------|
| `enable_managed_identity` | User-Assigned Managed Identity | `true` | **Recommended by**: Storage, Service Bus, Event Grid, SQL, Key Vault |
| `enable_vnet` | Virtual Network Spoke | `true` | None |
| `enable_observability` | Log Analytics + App Insights | `true` | **Required by**: Container Apps |
| `enable_key_vault` | Key Vault with RBAC | `true` | Uses: Managed Identity, SQL (stores password) |
| `enable_storage` | Storage Account | `true` | Uses: Managed Identity, VNet |
| `enable_service_bus` | Service Bus Namespace | `true` | Uses: Managed Identity |
| `enable_event_grid` | Event Grid Domain | `true` | Uses: Managed Identity, Service Bus |
| `enable_sql` | SQL Server & Database | `true` | Uses: Managed Identity, VNet |
| `enable_container_apps` | Container Apps Environment | `true` | **Requires**: Observability |

---

## Resource Dependencies

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RECURSOS INDEPENDENTES                                │
│  (podem ser criados sem dependências)                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  ✅ Resource Group      - Sempre criado (base de tudo)                       │
│  🔐 Managed Identity    - Opcional (enable_managed_identity)                 │
│      ⚠️  RECOMENDADO por: Storage, Service Bus, Event Grid, SQL, Key Vault  │
│  🌐 VNet Spoke          - Opcional (enable_vnet)                             │
│  📊 Observability       - Opcional (enable_observability)                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      RECURSOS COM DEPENDÊNCIAS OPCIONAIS                     │
│  (podem usar outros recursos se habilitados)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  📦 Storage Account                                                          │
│      └── Usa: Managed Identity (RBAC), VNet (network rules)                  │
│  📨 Service Bus                                                              │
│      └── Usa: Managed Identity (RBAC)                                        │
│  ⚡ Event Grid                                                               │
│      └── Usa: Managed Identity (RBAC), Service Bus (subscriptions)           │
│  🗄️ SQL Server & Database                                                   │
│      └── Usa: Managed Identity (RBAC), VNet (firewall rules)                 │
│  🔐 Key Vault                                                                │
│      └── Usa: Managed Identity (RBAC)                                        │
│      └── Armazena: SQL password (se enable_sql=true)                         │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      RECURSOS COM DEPENDÊNCIAS OBRIGATÓRIAS                  │
│  (REQUEREM outros recursos para funcionar)                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  📦 Container Apps                                                           │
│      └── REQUER: Observability (Log Analytics workspace_id)                  │
│      └── Usa: VNet (infrastructure_subnet_id) [opcional]                     │
│      ⚠️  NÃO será criado se enable_observability = false                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Dependency Matrix

| Recurso | Depende de (OBRIGATÓRIO) | Usa (OPCIONAL) | Condição de Criação |
|---------|-------------------------|----------------|---------------------|
| Resource Group | - | - | Sempre criado |
| Managed Identity | Resource Group | - | `enable_managed_identity = true` |
| VNet Spoke | Resource Group | - | `enable_vnet = true` |
| Observability | Resource Group | - | `enable_observability = true` |
| Storage Account | Resource Group | Managed Identity, VNet | `enable_storage = true` |
| Service Bus | Resource Group | Managed Identity | `enable_service_bus = true` |
| Event Grid | Resource Group | Managed Identity, Service Bus | `enable_event_grid = true` |
| SQL | Resource Group | Managed Identity, VNet | `enable_sql = true` |
| Key Vault | Resource Group | Managed Identity, SQL* | `enable_key_vault = true` |
| **Container Apps** | **Observability** | VNet | `enable_container_apps = true AND enable_observability = true` |

> \* Key Vault depends on SQL only to store the generated password. If `enable_sql = false`, Key Vault is created without secrets.

---

## Usage Examples

### Deploy Completo (all resources)
```hcl
name = "myplatform"
# All enable_* flags default to true
```

### Base Infrastructure Only
```hcl
name = "myplatform"
enable_managed_identity = false
enable_vnet             = true
enable_observability    = true
enable_key_vault        = false
enable_storage          = false
enable_service_bus      = false
enable_event_grid       = false
enable_sql              = false
enable_container_apps   = false
```

### Messaging Only (Service Bus + Event Grid)
```hcl
name = "myplatform"
enable_managed_identity = true   # Recommended for RBAC
enable_vnet             = false
enable_observability    = false
enable_key_vault        = false
enable_storage          = false
enable_service_bus      = true
enable_event_grid       = true
enable_sql              = false
enable_container_apps   = false
```

### Database Only (SQL + Key Vault)
```hcl
name = "myplatform"
enable_managed_identity = true   # Recommended for RBAC
enable_vnet             = false
enable_observability    = false
enable_key_vault        = true   # Stores SQL password
enable_storage          = false
enable_service_bus      = false
enable_event_grid       = false
enable_sql              = true
enable_container_apps   = false
```

### Container Apps (requires Observability)
```hcl
name = "myplatform"
enable_managed_identity = false
enable_vnet             = true   # Optional but recommended
enable_observability    = true   # REQUIRED for Container Apps
enable_key_vault        = false
enable_storage          = false
enable_service_bus      = false
enable_event_grid       = false
enable_sql              = false
enable_container_apps   = true
```

---

## Business Rules

### Platform Identity

- **Single input**: Only `name` is required (lowercase alphanumeric)
- **Region**: Fixed to `eastus2` (not configurable via pipeline)
- **No environment variable**: Platform is unique, identified by `name` + `location`

### SQL Server

- **Default admin user**: `sqladmin` (hardcoded, not passed via pipeline)
- **Password**: Auto-generated with `random_password` (16 chars minimum: 1 lowercase, 1 uppercase, 1 numeric, 1 special)
- **Storage**: Automatically stored in Key Vault as `sql-admin-password` secret (if enabled)
- **Azure AD Admin**: Configured via `data.azurerm_client_config.current.object_id` (current principal)
- **TLS Minimum**: 1.2 enforced
- **System-Assigned Identity**: Enabled for RBAC and Azure AD authentication
- **Version**: 12.0 (SQL Server 2020 compatible)

### Storage Account

- **Shared Keys**: Disabled (`shared_access_key_enabled = false`)
- **Azure AD Only**: Uses Azure AD authentication exclusively (`storage_use_azuread = true`)
- **RBAC Role**: Storage Blob Data Contributor assigned to Managed Identity (if enabled)
- **TLS Minimum**: 1.2 enforced
- **Blob Properties**:
  - Versioning: Enabled
  - Delete retention: 7 days
  - Container delete retention: 7 days
- **Containers**: Created AFTER RBAC role assignment to ensure permissions are propagated
- **Network Access**: Public endpoint enabled (configurable via vnet_subnet_ids for firewall rules)

### Key Vault

- **RBAC Authorization**: Always enabled (`enable_rbac_authorization = true`)
- **RBAC Propagation**: Uses `time_sleep` with 180s delay to wait for RBAC propagation before creating secrets
- **Soft Delete**: 7-day retention (safeguard for accidental deletion recovery)
- **Purge Protection**: Disabled (to allow cleanup during terraform destroy)
- **SKU**: Standard tier
- **Current Principal**: Automatically granted Key Vault Administrator role via uuidv5
- **No secret exposure**: Outputs only contain IDs and URIs, never secret values

### Container Apps

- **Requires Observability**: Will not be created if `enable_observability = false` (validation enforced)
- **VNet Integration**: Optional - uses delegated subnet (`Microsoft.App/environments`) with `/27` minimum size
- **Workload Profile**: Required when using delegated subnet (Consumption profile)
- **Lifecycle**: Uses `ignore_changes` on `workload_profile` to prevent unnecessary recreation
- **Internal Load Balancer**: Enabled when infrastructure_subnet_id is provided
- **Log Analytics**: Reference to workspace_id is required (comes from Observability module)

## Naming Conventions

All resources follow [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) standards with deterministic MD5 suffixes for global uniqueness:

### Naming Pattern Details

- **MD5 Suffix**: Generated from `substr(md5(var.name), 0, 4)` - same name always produces same suffix
- **Location Abbreviations**: eastus2=eus2, westus2=wus2, etc.
- **Deterministic**: NO random suffixes - ensures stable resource names across applies

| Resource | Pattern | Example | Notes |
|----------|---------|---------|-------|
| Resource Group | `rg-{name}-{region}` | `rg-myplatform-eus2` | Lifecycle: prevent_destroy=true |
| Virtual Network | `vnet-{name}-{region}` | `vnet-myplatform-eus2` | Contains default + delegated subnets |
| Container Apps Subnet | `snet-ca-{name}-{region}` | `snet-ca-myplatform-eus2` | /27 minimum, delegated to Microsoft.App/environments |
| Managed Identity | `id-{name}-{region}` | `id-myplatform-eus2` | User-Assigned type |
| Key Vault | `kv{name}{region}{md5}` | `kvmyplatformeus2abc1` | RBAC-enabled, 180s RBAC propagation delay |
| Storage Account | `st{name}{region}{md5}` | `stmyplatformeus2abc1` | No shared keys, Azure AD only, blobs + containers |
| Service Bus | `sb-{name}-{region}-{md5}` | `sb-myplatform-eus2-abc1` | Premium tier, includes Queue and Topic |
| Event Grid Domain | `evgd-{name}-{region}` | `evgd-myplatform-eus2` | Domain type for event routing, Service Bus integration |
| SQL Server | `sql-{name}-{region}-{md5}` | `sql-myplatform-eus2-abc1` | System-Assigned identity, AAD admin, TLS 1.2+ |
| SQL Database | `sqldb-{name}-{region}` | `sqldb-myplatform-eus2` | Elastic pool compatible, diagnostic logging |
| Log Analytics | `log-{name}-{region}` | `log-myplatform-eus2` | 30-day retention, workspace for diagnostic settings |
| App Insights | `appi-{name}-{region}` | `appi-myplatform-eus2` | Type: web, linked to Log Analytics |
| Container Apps Env | `cae-{name}-{region}-{md5}` | `cae-myplatform-eus2-abc1` | Requires Log Analytics, workload profile dynamic, /27 delegated subnet optional |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
│         (Declarative workflow with feature flags)        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Terraform Modules                       │
├─────────────────────────────────────────────────────────┤
│ Foundation  │ naming, resource-group                     │
│ Networking  │ vnet-spoke                                 │
│ Security    │ managed-identity, key-vault                │
│ Workloads   │ storage, service-bus, event-grid,          │
│             │ observability, sql, container-apps         │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Azure Resources                        │
└─────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
platform-as-a-service-stack/
├── .github/
│   └── workflows/
│       └── deploy.yml                # GitHub Actions workflow
├── terraform/
│   ├── modules/
│   │   ├── foundation/
│   │   │   ├── naming/              # Naming convention module
│   │   │   └── resource-group/      # Resource group module
│   │   ├── networking/
│   │   │   └── vnet-spoke/          # Virtual network module
│   │   ├── security/
│   │   │   ├── managed-identity/    # Managed identity module
│   │   │   └── key-vault/           # Key vault module
│   │   └── workloads/
│   │       ├── storage-account/     # Storage account module
│   │       ├── service-bus/         # Service Bus module
│   │       ├── event-grid/          # Event Grid module
│   │       ├── observability/       # Log Analytics + App Insights
│   │       ├── sql/                 # SQL Server & Database
│   │       └── container-apps/      # Container Apps module
│   ├── backend.tf                   # Remote state configuration
│   ├── providers.tf                 # Provider configuration
│   ├── main.tf                      # Root module orchestration
│   ├── variables.tf                 # Input variables with feature flags
│   └── outputs.tf                   # Platform outputs
├── prompt.md                        # Project specification
└── README.md                        # This file
```

---

## Technical Constraints (Azure Provider 4.57+)

### Required Providers

The following providers are required and automatically configured:

- **azurerm**: 4.57+ - Azure resource management
- **random**: 3.8+ - Random value generation (used for SQL passwords)
- **time**: 0.13+ - Time-based operations (RBAC propagation delays)

### Deprecated Attributes - DO NOT USE

| ❌ Deprecated | ✅ Use Instead |
|--------------|----------------|
| `enable_https_traffic_only` (Storage) | `https_traffic_only_enabled` |
| `zone_redundant` (Service Bus) | `premium_messaging_partitions` |
| `enable_partitioning` (Service Bus Queue/Topic) | Removed - Controlled at namespace |
| `metric` (Diagnostic Settings) | `enabled_metric` |

### Unsupported Resources

- `azurerm_servicebus_namespace_network_rule_set` - Does not exist in provider 4.x

### SQL Server Diagnostic Settings

Diagnostic Settings at SQL Server level DO NOT support:
- `SQLSecurityAuditEvents` - Requires SQL Database Auditing enabled
- `DevOpsOperationsAudit` - Requires SQL Database Auditing enabled

Use diagnostic settings at database level instead.

---

## Documentation

- [prompt.md](prompt.md) - Complete project specification and business rules
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

## Support

- **Owner**: Platform Engineering Team
- **Channel**: #platform-support
- **Issues**: GitHub Issues

## License

MIT License - see [LICENSE](LICENSE) for details

---

**Version**: 3.0.0  
**Terraform**: 1.9.0+  
**AzureRM Provider**: 4.57+  
**Random Provider**: 3.8+  
**Time Provider**: 0.13+  
**Last Updated**: January 2026
