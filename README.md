# Platform as a Service Stack

Azure infrastructure platform for accelerating product development through composable, secure, and reusable infrastructure capabilities.

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

- **Default admin user**: `sql_admin` (hardcoded, not passed via pipeline)
- **Password**: Auto-generated with `random_password`
- **Storage**: Automatically stored in Key Vault (if enabled)
- **Azure AD Admin**: Optional, configured via variables

### Security

- **Managed Identity**: Default authentication method (passwordless)
- **RBAC-based**: All access control via Azure RBAC
- **TLS 1.2+**: Minimum TLS version for all resources
- **No shared keys**: Storage Account uses Azure AD authentication only

### Key Vault

- **RBAC Authorization**: Always enabled (`enable_rbac_authorization = true`)
- **RBAC Propagation**: Uses `time_sleep` (180s) to wait for RBAC propagation
- **No secret exposure**: Outputs only contain IDs and URIs, never secret values

### Container Apps

- **Requires Observability**: Will not be created if `enable_observability = false`
- **VNet Integration**: Uses delegated subnet with `/27` minimum size
- **Workload Profile**: Required when using delegated subnet
- **Lifecycle**: Uses `ignore_changes` on `workload_profile` to prevent unnecessary recreation

### Role Assignments

- **Deterministic UUIDs**: All role assignments use `uuidv5()` to generate stable IDs
- **No destroy/recreate**: Same inputs always generate the same UUID
- **Pattern**: `uuidv5("dns", "${scope_id}-${principal_id}-${role_suffix}")`

---

## Naming Conventions

All resources follow [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) standards:

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-{name}-{region}` | `rg-myplatform-eus2` |
| Virtual Network | `vnet-{name}-{region}` | `vnet-myplatform-eus2` |
| Managed Identity | `id-{name}-{region}` | `id-myplatform-eus2` |
| Key Vault | `kv{name}{region}{suffix}` | `kvmyplatformeus2abc1` |
| Storage Account | `st{name}{region}{suffix}` | `stmyplatformeus2abc1` |
| Service Bus | `sbns-{name}-{region}` | `sbns-myplatform-eus2` |
| Event Grid | `evgd-{name}-{region}` | `evgd-myplatform-eus2` |
| SQL Server | `sql-{name}-{region}` | `sql-myplatform-eus2` |
| Log Analytics | `log-{name}-{region}` | `log-myplatform-eus2` |
| App Insights | `appi-{name}-{region}` | `appi-myplatform-eus2` |
| Container Apps Env | `cae-{name}-{region}` | `cae-myplatform-eus2` |

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

## Technical Constraints (Azure Provider 4.x)

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

**Version**: 2.0.0  
**Terraform**: 1.9.0+  
**AzureRM Provider**: 4.x  
**Last Updated**: January 2026
