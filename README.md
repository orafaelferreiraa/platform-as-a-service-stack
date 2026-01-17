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
1. Go to **Actions** → **Platform Provisioning**
2. Click **Run workflow**
3. Fill in the required inputs (team, product, environment)
4. Select resources to provision using checkboxes
5. Review the plan and approve

#### Via Terraform CLI (Local Development)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Features

### Composable Resources

Choose exactly what you need:
- ✅ VNet Spoke with NSG
- ✅ Managed Identity (User-Assigned)
- ✅ Key Vault with RBAC
- ✅ Storage Account
- ✅ Service Bus (Queues & Topics)
- ✅ Event Grid Topics
- ✅ Observability (Log Analytics + App Insights)
- ✅ SQL Server & Database
- ✅ Redis Cache
- ✅ Container Apps

### Security First

- **Managed Identity** as default authentication (no passwords)
- **RBAC-based** access control
- **TLS 1.2+** minimum
- **Network isolation** (Private Endpoints, NSG)
- **Microsoft Entra authentication** for SQL

### Official Naming Conventions

All resources follow [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming) standards:

```
rg-api-platform-dev-eus
vnet-api-platform-dev-eus
kv-apiplatformdeveus
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
│         (Declarative workflow with checkboxes)          │
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
│             │ observability, sql, redis, container-apps  │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Azure Resources                        │
└─────────────────────────────────────────────────────────┘
```

## Repository Structure

```
platform-as-a-service-stack/
├── .github/
│   └── workflows/
│       └── provision-platform.yml    # GitHub Actions workflow
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
│   │       ├── redis-cache/         # Redis Cache module
│   │       └── container-apps/      # Container Apps module
│   ├── backend.tf                   # Remote state configuration
│   ├── providers.tf                 # Provider configuration
│   ├── main.tf                      # Root module orchestration
│   ├── variables.tf                 # Input variables with feature flags
│   ├── outputs.tf                   # Platform outputs
│   └── terraform.tfvars.example     # Example configuration
├── ARCHITECTURE.md                  # Detailed architecture documentation
└── README.md                        # This file
```

## Example Usage

### Provision a complete stack

```yaml
# GitHub Actions workflow inputs
team: platform
product: api
environment: dev
location: eastus2

# Enable resources
enable_vnet: true
enable_managed_identity: true
enable_key_vault: true
enable_storage_account: true
enable_service_bus: true
enable_observability: true
```

**Result:**
```
Resource Group:  rg-api-platform-dev-eus
VNet:            vnet-api-platform-dev-eus
Identity:        id-api-platform-dev-eus
Key Vault:       kv-apiplatformdeveus
Storage:         stapiplatformdeveus
Service Bus:     sbns-api-platform-dev-eus
Log Analytics:   log-api-platform-dev-eus
App Insights:    appi-api-platform-dev-eus
```

### Add SQL Server later

Simply re-run the workflow with:
```yaml
enable_sql: true
sql_admin_login: "admin@contoso.com"
sql_admin_object_id: "uuid-here"
```

Terraform detects the new resource and provisions only what's missing.

## Key Design Decisions

### 1. Modular & Composable
Each module is **atomic** and can be used independently or composed together.

### 2. Feature Flags
Resources are provisioned conditionally using boolean flags:
```hcl
enable_vnet = true
enable_key_vault = true
enable_sql = false
```

### 3. Managed Identity Everywhere
All compatible resources use Managed Identity for authentication:
- Container Apps → Key Vault
- Storage Account → RBAC
- Service Bus → RBAC
- SQL Server → Microsoft Entra

### 4. Explicit Dependencies
Module dependencies are explicit via `depends_on` and output references.

### 5. No Hardcoded Values
Everything flows from a single input: `product_identity { team, product }`

## Documentation

- [**ARCHITECTURE.md**](ARCHITECTURE.md) - Detailed architecture, best practices, and anti-patterns
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Follow Terraform best practices
4. Test your changes
5. Submit a Pull Request

## Support

- **Owner**: Platform Engineering Team
- **Channel**: #platform-support
- **Issues**: GitHub Issues

## License

MIT License - see [LICENSE](LICENSE) for details

---

**Version**: 1.0.0  
**Terraform**: 1.9.0+  
**AzureRM Provider**: 4.57.0  
**Last Updated**: January 2026