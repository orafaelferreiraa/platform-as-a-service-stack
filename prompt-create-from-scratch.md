# Azure Platform as a Service Stack - Blueprint para Criação do Zero

**Objetivo**: Criar uma infraestrutura Azure completa e modular usando Terraform + GitHub Actions para servir como plataforma interna (IaaS) para times de produto.

---

## 🎯 Visão Geral do Projeto

### Stack Tecnológica
- **Cloud Provider**: Azure
- **IaC**: Terraform 1.9.0+ (provider azurerm 4.57+)
- **Additional Providers**: random ~> 3.8, time ~> 0.13
- **CI/CD**: GitHub Actions
- **Autenticação**: Service Principal + Client Secret (variáveis ARM_*)

### Princípios de Design
1. **Modularidade Total**: Cada recurso Azure é um módulo Terraform independente
2. **Feature Flags**: Todos os recursos são opcionais via variáveis `enable_<recurso>`
3. **Zero Hardcoding**: Tudo configurável via variáveis (exceto região default)
4. **Segurança First**: RBAC com Managed Identity, sem chaves de acesso
5. **Observability Built-in**: Diagnostic Settings integrados quando habilitado

---

## 📋 Recursos da Plataforma

### Fundação (Foundation)
- **Resource Group** - Sempre criado com lifecycle `prevent_destroy = true`
- **Naming Convention** - Sufixos MD5 determinísticos para nomes globalmente únicos
  - Pattern: `substr(md5(var.name), 0, 4)` = sempre mesmo suffix para mesmo name
  - Location abbreviations: eastus2=eus2, westus2=wus2, etc
- **Managed Identity** - User-Assigned, Opcional mas RECOMENDADO para RBAC

### Rede (Networking)
- **VNet Spoke** - Opcional, com subnet default e subnet delegada para Container Apps

### Segurança (Security)
- **Key Vault** - RBAC-enabled, armazena secrets (ex: SQL password)
- **Managed Identity** - Principal de segurança para RBAC

### Workloads
- **Observability** - Log Analytics (30-day retention) + Application Insights (web type)
- **Storage Account** - Autenticação Azure AD apenas, sem chaves (`shared_access_key_enabled = false`)
  - Blobs com versioning e 7-day delete retention
  - Containers criados após RBAC propagation (time_sleep 180s)
- **Service Bus** - Namespace Premium com Queue e Topic inclusos
- **Event Grid** - Domain tipo com subscription para Service Bus
- **SQL Server + Database** - Senha auto-gerada (`random_password`) e armazenada no Key Vault
  - Version: 12.0, AAD admin, System-Assigned identity
  - TLS 1.2+ obrigatório
- **Container Apps Environment** - REQUER Observability
  - Workload profile dinâmico para /27 subnet delegada
  - Lifecycle `ignore_changes` em workload_profile

---

## 🔗 Mapa de Dependências

```
┌─────────────────────────────────────────────────────────────────┐
│ CAMADA 1: Fundação (sem dependências)                           │
├─────────────────────────────────────────────────────────────────┤
│ ✅ Resource Group                                                │
│ 🔐 Managed Identity (opcional mas RECOMENDADO)                   │
│ 🌐 VNet Spoke                                                    │
│ 📊 Observability (Log Analytics + App Insights)                  │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ CAMADA 2: Workloads (dependências opcionais)                    │
├─────────────────────────────────────────────────────────────────┤
│ 📦 Storage Account                                               │
│    └─ Usa: Managed Identity (RBAC), VNet (network rules)        │
│                                                                  │
│ 📨 Service Bus                                                   │
│    └─ Usa: Managed Identity (RBAC)                              │
│                                                                  │
│ ⚡ Event Grid                                                    │
│    └─ Usa: Managed Identity, Service Bus (subscriptions)        │
│                                                                  │
│ 🗄️ SQL Server + Database                                        │
│    └─ Usa: Managed Identity (RBAC), VNet (firewall)             │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│ CAMADA 3: Segurança e Compute (dependências cruzadas)           │
├─────────────────────────────────────────────────────────────────┤
│ 🔐 Key Vault                                                     │
│    └─ Usa: Managed Identity (RBAC)                              │
│    └─ Armazena: SQL password (depends_on SQL para evitar ciclo) │
│                                                                  │
│ 📦 Container Apps Environment                                    │
│    └─ REQUER: Observability (obrigatório)                       │
│    └─ Usa: VNet (subnet delegada + workload_profile)            │
└─────────────────────────────────────────────────────────────────┘
```

### Feature Flags e Dependências Críticas

| Flag | Recurso | Depende de (OBRIGATÓRIO) | Usa (OPCIONAL) |
|------|---------|-------------------------|----------------|
| `enable_managed_identity` | Managed Identity | - | - |
| `enable_vnet` | VNet Spoke | - | - |
| `enable_observability` | Log Analytics + App Insights | - | - |
| `enable_storage` | Storage Account | - | Managed Identity, VNet |
| `enable_service_bus` | Service Bus | - | Managed Identity |
| `enable_event_grid` | Event Grid | - | Managed Identity, Service Bus |
| `enable_sql` | SQL Server + DB | - | Managed Identity, VNet |
| `enable_key_vault` | Key Vault | SQL (se habilitado) | Managed Identity |
| `enable_container_apps` | Container Apps | **Observability** | VNet |

---

## 🏗️ Estrutura de Arquivos Terraform

```
terraform/
├── backend.tf              # Azure Storage backend config
├── main.tf                 # Orquestração de todos os módulos
├── outputs.tf              # Outputs consolidados
├── providers.tf            # Provider azurerm + required_providers
├── variables.tf            # Feature flags + configurações
├── test.tfvars            # Exemplo de configuração
└── modules/
    ├── foundation/
    │   ├── naming/         # Convenção de nomenclatura
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── resource-group/
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── networking/
    │   └── vnet-spoke/
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── security/
    │   ├── key-vault/
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── managed-identity/
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    └── workloads/
        ├── container-apps/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── event-grid/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── observability/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── service-bus/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        ├── sql/
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── variables.tf
        └── storage-account/
            ├── main.tf
            ├── outputs.tf
            └── variables.tf
```

---

## 🔧 Regras de Implementação Críticas

### 1. Naming Convention com MD5 Determinístico

**OBRIGATÓRIO**: Usar `md5(var.name)` para sufixos, NUNCA `random_string`:

```hcl
locals {
  name   = lower(var.name)
  suffix = substr(md5(var.name), 0, 4)  # DETERMINÍSTICO
  
  # Recursos com nomes globalmente únicos
  key_vault       = "kv${local.name}${local.location_abbr}${local.suffix}"
  storage_account = "st${local.name}${local.location_abbr}${local.suffix}"
  sql_server      = "sql-${local.name}-${local.location_abbr}-${local.suffix}"
  
  # Recursos sem sufixo (escopo do resource group)
  resource_group      = "rg-${local.name}-${local.location_abbr}"
  managed_identity    = "id-${local.name}-${local.location_abbr}"
  vnet                = "vnet-${local.name}-${local.location_abbr}"
}
```

**Por quê?** `random_string` muda a cada apply, causando destruição de recursos!

### 2. Provider Configuration

```hcl
terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true  # OBRIGATÓRIO para Storage sem chaves (shared_access_key_enabled = false)
}
```

### 3. Backend Configuration (State Remoto)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
    use_azuread_auth     = true  # Storage sem chaves
  }
}
```

### 4. Feature Flags (variables.tf)

```hcl
# Inputs obrigatórios
variable "name" {
  description = "Nome único da plataforma (lowercase alphanumeric)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.name))
    error_message = "Name must contain only lowercase letters and numbers"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Feature flags - todos true por padrão
variable "enable_managed_identity" {
  type    = bool
  default = true
  description = "RECOMENDADO - Required by Storage, Service Bus, Event Grid, SQL, Key Vault"
}

variable "enable_vnet" {
  type    = bool
  default = true
}

variable "enable_observability" {
  type    = bool
  default = true
  description = "OBRIGATÓRIO para Container Apps"
}

variable "enable_key_vault" {
  type    = bool
  default = true
}

variable "enable_storage" {
  type    = bool
  default = true
}

variable "enable_service_bus" {
  type    = bool
  default = true
}

variable "enable_event_grid" {
  type    = bool
  default = true
}

variable "enable_sql" {
  type    = bool
  default = true
}

variable "enable_container_apps" {
  type    = bool
  default = true
}

# SQL Configuration
variable "sql_administrator_login" {
  description = "SQL admin username"
  type        = string
  default     = "sqladmin"
}

# Tags
variable "tags" {
  type    = map(string)
  default = {}
}
```

### 5. Count Conditions - REGRA DE OURO

**❌ NUNCA** usar null checks em count:
```hcl
# ❌ ERRADO - Causa erro "depends on resource attributes"
count = var.log_analytics_workspace_id != null ? 1 : 0
```

**✅ SEMPRE** usar boolean flags:
```hcl
# ✅ CORRETO - Usa apenas boolean determinístico
count = var.enable_observability ? 1 : 0
```

### 6. Role Assignments com uuidv5

**OBRIGATÓRIO**: Usar `uuidv5` para IDs determinísticos:

```hcl
resource "azurerm_role_assignment" "example" {
  name                 = uuidv5("dns", "${scope_id}-${principal_id}-role-suffix")
  scope                = var.scope_id
  role_definition_name = "Role Name"
  principal_id         = var.principal_id
}
```

**Por quê?** Sem `name`, Azure gera UUID aleatório = destroy/recreate a cada apply!

### 7. Key Vault - Configuração Obrigatória

```hcl
resource "azurerm_key_vault" "main" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true  # OBRIGATÓRIO para RBAC!
  
  tags = var.tags
}

# RBAC para o usuário atual
resource "azurerm_role_assignment" "current_admin" {
  name                 = uuidv5("dns", "${azurerm_key_vault.main.id}-${var.current_principal_id}-admin")
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.current_principal_id
}

# Aguardar propagação do RBAC (180 segundos)
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.current_admin]
  create_duration = "180s"
  
  triggers = {
    role_assignment_id = azurerm_role_assignment.current_admin.id
  }
}

# Secrets só depois do RBAC propagar
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [time_sleep.wait_for_rbac]
}
```

**⚠️ NUNCA** expor valores de secrets em outputs:
```hcl
# ✅ PERMITIDO
output "id" {
  value = azurerm_key_vault.main.id
}

output "secret_ids" {
  value = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

# ❌ PROIBIDO
output "secret_values" {
  value = { for k, v in azurerm_key_vault_secret.secrets : k => v.value }
}
```

### 8. SQL Server - Senha Automática

```hcl
# Gerar senha aleatória
resource "random_password" "sql_admin" {
  length           = 16
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"
  
  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = var.current_principal_id
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Output da senha (para Key Vault)
output "admin_password" {
  description = "SQL admin password (to be stored in Key Vault)"
  value       = random_password.sql_admin.result
  sensitive   = true
}
```

### 9. Storage Account - Sem Chaves

```hcl
resource "azurerm_storage_account" "main" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true  # NÃO enable_https_traffic_only
  shared_access_key_enabled       = false # Apenas Azure AD
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 7
    }
  }
  
  tags = var.tags
}

# RBAC para Managed Identity
resource "azurerm_role_assignment" "managed_identity_blob_contributor" {
  count                = var.enable_managed_identity_rbac ? 1 : 0
  name                 = uuidv5("dns", "${azurerm_storage_account.main.id}-${var.managed_identity_id}-blob-contributor")
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.managed_identity_id
}

# Container criado APÓS RBAC
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
  
  depends_on = [azurerm_role_assignment.managed_identity_blob_contributor]
}
```

### 10. Container Apps - Workload Profile com VNet

```hcl
resource "azurerm_container_app_environment" "main" {
  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.infrastructure_subnet_id != null ? true : false
  
  # Workload profile OBRIGATÓRIO quando usando subnet delegada
  dynamic "workload_profile" {
    for_each = var.infrastructure_subnet_id != null ? [1] : []
    content {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }
  }
  
  tags = var.tags
  
  lifecycle {
    ignore_changes = [workload_profile]
  }
}
```

### 11. Event Grid - Atributos Diretos

```hcl
# ❌ ERRADO - NÃO usar dynamic block
dynamic "service_bus_topic_endpoint_id" {
  for_each = var.service_bus_topic_id != null ? [1] : []
  content {
    service_bus_topic_endpoint_id = var.service_bus_topic_id
  }
}

# ✅ CORRETO - Atributo direto
resource "azurerm_eventgrid_event_subscription" "servicebus" {
  count                      = var.enable_service_bus_integration ? 1 : 0
  name                       = "sub-${var.name}"
  scope                      = azurerm_eventgrid_domain.main.id
  service_bus_topic_endpoint_id = var.service_bus_topic_id
}
```

### 12. Diagnostic Settings - Categorias Corretas

**SQL Server** (no nível do servidor - categorias limitadas):
```hcl
resource "azurerm_monitor_diagnostic_setting" "server" {
  count                      = var.enable_observability ? 1 : 0
  name                       = "diag-${var.server_name}"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  # Categorias suportadas no SQL Server
  enabled_log {
    category = "SQLSecurityAuditEvents"  # Requer auditing habilitado
  }
  
  enabled_metric {
    category = "AllMetrics"
  }
}
```

**SQL Database** (mais categorias disponíveis):
```hcl
resource "azurerm_monitor_diagnostic_setting" "database" {
  count                      = var.enable_observability ? 1 : 0
  name                       = "diag-${var.database_name}"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "SQLInsights"
  }
  
  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }
  
  enabled_log {
    category = "Errors"
  }
  
  enabled_metric {
    category = "AllMetrics"
  }
}
```

### 13. Evitar Ciclos de Dependência

**Problema**: Key Vault precisa do SQL password, mas SQL pode precisar de RBAC no Key Vault.

**Solução**: Separar RBAC em recurso independente no main.tf:

```hcl
# main.tf
module "sql" {
  count  = var.enable_sql ? 1 : 0
  source = "./modules/workloads/sql"
  # ...
}

module "key_vault" {
  count   = var.enable_key_vault ? 1 : 0
  source  = "./modules/security/key-vault"
  secrets = var.enable_sql ? {
    "sql-admin-password" = module.sql[0].admin_password
  } : {}
  
  depends_on = [module.sql]  # Evita ciclo
}

# RBAC separado - APÓS ambos os módulos
resource "azurerm_role_assignment" "sql_key_vault_access" {
  count                = var.enable_sql && var.enable_key_vault && var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${module.key_vault[0].id}-${module.sql[0].identity_principal_id}-secrets-officer")
  scope                = module.key_vault[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.sql[0].identity_principal_id
  
  depends_on = [module.sql, module.key_vault]
}
```

### 14. Validação de Dependências

```hcl
# Container Apps requer Observability
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability (enable_observability = true)' && exit 1"
  }
}
```

---

## 📦 Exemplo de main.tf (Orquestração)

```hcl
# Get current client config
data "azurerm_client_config" "current" {}

locals {
  base_tags = merge(
    {
      "managed-by" = "terraform"
      "platform"   = var.name
    },
    var.tags
  )
}

# Validation
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability' && exit 1"
  }
}

# Foundation: Naming
module "naming" {
  source   = "./modules/foundation/naming"
  name     = var.name
  location = var.location
}

# Foundation: Resource Group
module "resource_group" {
  source   = "./modules/foundation/resource-group"
  name     = module.naming.resource_group
  location = var.location
  tags     = local.base_tags
}

# Security: Managed Identity
module "managed_identity" {
  count               = var.enable_managed_identity ? 1 : 0
  source              = "./modules/security/managed-identity"
  name                = module.naming.managed_identity
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.base_tags
}

# Networking: VNet
module "vnet_spoke" {
  count                      = var.enable_vnet ? 1 : 0
  source                     = "./modules/networking/vnet-spoke"
  name                       = module.naming.vnet
  location                   = var.location
  resource_group_name        = module.resource_group.name
  container_apps_subnet_name = module.naming.subnet_container_apps
  tags                       = local.base_tags
}

# Workloads: Observability
module "observability" {
  count               = var.enable_observability ? 1 : 0
  source              = "./modules/workloads/observability"
  name                = var.name
  location            = var.location
  resource_group_name = module.resource_group.name
  naming              = module.naming
  tags                = local.base_tags
}

# Workloads: Storage Account
module "storage_account" {
  count                        = var.enable_storage ? 1 : 0
  source                       = "./modules/workloads/storage-account"
  name                         = module.naming.storage_account
  location                     = var.location
  resource_group_name          = module.resource_group.name
  managed_identity_id          = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  enable_managed_identity_rbac = var.enable_managed_identity
  vnet_subnet_ids              = var.enable_vnet ? [module.vnet_spoke[0].default_subnet_id] : []
  tags                         = local.base_tags
  enable_observability         = var.enable_observability
  log_analytics_workspace_id   = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Workloads: Service Bus
module "service_bus" {
  count                        = var.enable_service_bus ? 1 : 0
  source                       = "./modules/workloads/service-bus"
  name                         = module.naming.service_bus
  location                     = var.location
  resource_group_name          = module.resource_group.name
  managed_identity_id          = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  enable_managed_identity_rbac = var.enable_managed_identity
  tags                         = local.base_tags
  enable_observability         = var.enable_observability
  log_analytics_workspace_id   = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Workloads: Event Grid
module "event_grid" {
  count                          = var.enable_event_grid ? 1 : 0
  source                         = "./modules/workloads/event-grid"
  name                           = module.naming.event_grid_domain
  location                       = var.location
  resource_group_name            = module.resource_group.name
  managed_identity_id            = var.enable_managed_identity ? module.managed_identity[0].id : null
  service_bus_topic_id           = var.enable_service_bus ? module.service_bus[0].topic_id : null
  enable_service_bus_integration = var.enable_service_bus
  tags                           = local.base_tags
  enable_observability           = var.enable_observability
  log_analytics_workspace_id     = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Workloads: SQL
module "sql" {
  count                      = var.enable_sql ? 1 : 0
  source                     = "./modules/workloads/sql"
  server_name                = module.naming.sql_server
  database_name              = module.naming.sql_database
  location                   = var.location
  resource_group_name        = module.resource_group.name
  administrator_login        = var.sql_administrator_login
  current_principal_id       = data.azurerm_client_config.current.object_id
  vnet_subnet_ids            = var.enable_vnet ? [module.vnet_spoke[0].default_subnet_id] : []
  tags                       = local.base_tags
  enable_observability       = var.enable_observability
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_id : null
}

# Security: Key Vault
module "key_vault" {
  count                        = var.enable_key_vault ? 1 : 0
  source                       = "./modules/security/key-vault"
  name                         = module.naming.key_vault
  location                     = var.location
  resource_group_name          = module.resource_group.name
  tenant_id                    = data.azurerm_client_config.current.tenant_id
  current_principal_id         = data.azurerm_client_config.current.object_id
  managed_identity_id          = var.enable_managed_identity ? module.managed_identity[0].principal_id : null
  enable_managed_identity_rbac = var.enable_managed_identity
  secrets = var.enable_sql ? {
    "sql-admin-password" = module.sql[0].admin_password
  } : {}
  tags                       = local.base_tags
  enable_observability       = var.enable_observability
  log_analytics_workspace_id = var.enable_observability ? module.observability[0].log_analytics_id : null
  
  depends_on = [module.sql]
}

# Workloads: Container Apps
module "container_apps" {
  count                      = var.enable_container_apps && var.enable_observability ? 1 : 0
  source                     = "./modules/workloads/container-apps"
  name                       = module.naming.container_apps_environment
  location                   = var.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.observability[0].log_analytics_id
  infrastructure_subnet_id   = var.enable_vnet ? module.vnet_spoke[0].container_apps_subnet_id : null
  tags                       = local.base_tags
}

# RBAC: SQL access to Key Vault
resource "azurerm_role_assignment" "sql_key_vault_access" {
  count                = var.enable_sql && var.enable_key_vault && var.enable_managed_identity ? 1 : 0
  name                 = uuidv5("dns", "${module.key_vault[0].id}-${module.sql[0].identity_principal_id}-secrets-officer")
  scope                = module.key_vault[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.sql[0].identity_principal_id
  
  depends_on = [module.sql, module.key_vault]
}
```

---

## 🚀 GitHub Actions Workflow

### Secrets necessários
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`

### Workflow básico (.github/workflows/terraform-deploy.yml)

```yaml
name: Terraform Deploy

on:
  workflow_dispatch:
    inputs:
      name:
        description: 'Platform name (lowercase alphanumeric)'
        required: true
        type: string

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      TF_VAR_name: ${{ inputs.name }}
    
    defaults:
      run:
        shell: bash
        working-directory: terraform
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.14.x
      
      - name: Terraform Init
        run: |
          terraform init -input=false \
            -backend-config="resource_group_name=rg-paas" \
            -backend-config="storage_account_name=storagepaas" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=${{ env.TF_VAR_name }}.terraform.tfstate" \
            -backend-config="use_azuread_auth=true"
      
      - name: Terraform Validate
        run: terraform validate
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
```

---

## ✅ Checklist de Criação

### Estrutura de Pastas
- [ ] Criar estrutura `terraform/modules/` com todas as categorias
- [ ] Cada módulo tem `main.tf`, `variables.tf`, `outputs.tf`

### Módulos Foundation
- [ ] `naming/` - MD5 suffix + convenções de nomenclatura
- [ ] `resource-group/` - Resource group base

### Módulos Security
- [ ] `managed-identity/` - Managed Identity com outputs
- [ ] `key-vault/` - RBAC enabled + time_sleep + secrets sensíveis

### Módulos Networking
- [ ] `vnet-spoke/` - VNet com subnet default + subnet delegada para Container Apps

### Módulos Workloads
- [ ] `observability/` - Log Analytics + App Insights
- [ ] `storage-account/` - Sem chaves + RBAC + containers
- [ ] `service-bus/` - Premium + Queue + Topic + RBAC
- [ ] `event-grid/` - Domain + subscription Service Bus opcional
- [ ] `sql/` - Server + Database + senha automática + RBAC
- [ ] `container-apps/` - Environment + workload_profile dinâmico

### Arquivos Root
- [ ] `backend.tf` - Azure Storage backend com `use_azuread_auth`
- [ ] `providers.tf` - azurerm + required_providers
- [ ] `variables.tf` - Feature flags + configurações
- [ ] `main.tf` - Orquestração completa
- [ ] `outputs.tf` - Outputs consolidados
- [ ] `test.tfvars` - Exemplo de configuração

### GitHub Actions
- [ ] `.github/workflows/terraform-deploy.yml`
- [ ] Autenticação via ARM_* env vars
- [ ] Backend config dinâmico com input.name

### Validação
- [ ] `terraform init -backend=false` - Success
- [ ] `terraform validate` - Success
- [ ] `terraform fmt -recursive` - Todos formatados
- [ ] `terraform plan` com todos os recursos habilitados
- [ ] `terraform plan` com recursos individuais

---

## 📝 Notas Importantes

### Atributos Deprecated (Provider 4.x)

| ❌ NÃO USAR | ✅ USAR |
|------------|---------|
| `enable_https_traffic_only` | `https_traffic_only_enabled` |
| `zone_redundant` (Service Bus) | `premium_messaging_partitions` |
| `metric` (Diagnostic Settings) | `enabled_metric` |

### Região Padrão
- **eastus2** hardcoded como default em `variables.tf`
- NÃO passar como input na pipeline

### Usuário SQL Padrão
- **sqladmin** hardcoded como default
- Senha gerada com `random_password`

### Destroy via Portal
- NÃO criar action destroy na pipeline (problemas de RBAC)
- Delete manual do Resource Group no Azure Portal

---

## 🎓 Conceitos Importantes

### MD5 vs Random String
- **MD5**: Determinístico, mesmo input = mesmo output
- **Random**: Muda a cada apply = destroy/recreate de recursos

### Count com Condicionais
- Usar apenas boolean flags determinísticos
- NUNCA usar `!= null` ou `!= ""` com outputs de módulos condicionais

### RBAC Propagation
- Azure leva até 5 minutos para propagar RBAC
- Usar `time_sleep` de 180s antes de criar secrets no Key Vault

### Storage Account sem Chaves
- `shared_access_key_enabled = false`
- `storage_use_azuread = true` no provider
- RBAC obrigatório para criar containers

### Container Apps + VNet
- Subnet delegada para `Microsoft.App/environments`
- Tamanho mínimo `/27`
- `workload_profile` obrigatório quando usando subnet

---

## 🔍 Troubleshooting Comum

### Erro: "count depends on resource attributes"
**Causa**: Count usando null check de output de módulo condicional
**Solução**: Adicionar boolean flag separado

### Erro: "KeyBasedAuthenticationNotPermitted"
**Causa**: Storage Account sem `storage_use_azuread = true` no provider
**Solução**: Adicionar `storage_use_azuread = true` em providers.tf

### Erro: "does not have secrets get permission"
**Causa**: RBAC não propagado ou `enable_rbac_authorization = false`
**Solução**: Adicionar `time_sleep` de 180s + `enable_rbac_authorization = true`

### Erro: "ManagedEnvironmentSubnetIsDelegated"
**Causa**: Container Apps sem `workload_profile` block usando subnet delegada
**Solução**: Adicionar `dynamic "workload_profile"` com Consumption

### Role Assignment sempre recreated
**Causa**: Faltando `name` com uuidv5
**Solução**: `name = uuidv5("dns", "<unique-string>")`

---

## 📚 Referências Obrigatórias

### Antes de Começar
1. Consultar documentação oficial do Azure para cada recurso
2. Verificar Terraform Registry para provider azurerm 4.x
3. Validar naming conventions oficiais da Microsoft
4. Checar limites e SKUs disponíveis por região

### Durante Implementação
- Seguir estrutura de módulos proposta
- Implementar feature flags para tudo
- Testar com combinações diferentes de recursos
- Validar RBAC propagation com time_sleep

### Validação Final
```bash
cd terraform
terraform init -backend=false
terraform validate
terraform fmt -recursive -check
terraform plan -var-file=test.tfvars
```

---

**Versão**: 3.1 - Blueprint Implementado com Naming Convention Determinística
**Data**: Janeiro 2026
**Objetivo**: Criar plataforma Azure modular e escalável com Terraform + GitHub Actions
**Status**: ✅ Implementado com todas as regras de negócio preservadas
