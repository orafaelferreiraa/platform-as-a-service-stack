# Platform as a Service Stack - Prompt Consolidado v2.0

Atue como um Engenheiro de Plataforma Sênior especializado em Azure, com experiência prática em criar plataformas internas para habilitar times de produto, inovação e aplicações.

## Objetivo

Criar uma infraestrutura base de plataforma usando:
- **Azure** como cloud provider
- **Terraform** como Infrastructure as Code
- **GitHub Actions** como pipeline de CI/CD

Essa plataforma será consumida por times de produto como Infrastructure as a Service interna.

---

## Uso Obrigatório de Boas Práticas (MCP)

### Azure
Consulte obrigatoriamente a documentação oficial:
- Taxonomia e convenções oficiais de nomenclatura
- Limites, SKUs e modelos de consumo
- Suporte oficial a Managed Identity
- Padrões recomendados de segurança e arquitetura

### Terraform
Consulte obrigatoriamente o MCP oficial:
- Design correto de módulos reutilizáveis
- Organização de código
- Referências entre módulos e outputs
- Boas práticas de state, providers e dependências

### GitHub Actions
Consulte obrigatoriamente o MCP oficial:
- Design de workflows
- Inputs declarativos
- Segurança e manutenção de pipelines

---

## Escopo da Plataforma

### Modo de Criação

O usuário deve poder escolher entre:
1. **Criar todos os recursos** - Deploy completo da plataforma
2. **Criar recursos individuais** - Habilitar/desabilitar cada recurso via feature flags

### Feature Flags (Variáveis Booleanas)

Cada recurso deve ter uma variável `enable_<recurso>` para controle individual:

```hcl
# Feature flags - todos habilitados por padrão
variable "enable_vnet" {
  type    = bool
  default = true
}

variable "enable_observability" {
  type    = bool
  default = true
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

variable "enable_redis" {
  type    = bool
  default = true
}

variable "enable_container_apps" {
  type    = bool
  default = true
}
```

### Mapa de Dependências entre Recursos

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RECURSOS INDEPENDENTES                                │
│  (podem ser criados sem dependências)                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  ✅ Resource Group      - Sempre criado (base de tudo)                       │
│  ✅ Managed Identity    - Sempre criado (base de autenticação)               │
│  ✅ VNet Spoke          - Independente (enable_vnet)                         │
│  ✅ Observability       - Independente (enable_observability)                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      RECURSOS COM DEPENDÊNCIAS OPCIONAIS                     │
│  (podem usar outros recursos se habilitados)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  📦 Storage Account                                                          │
│      └── Usa: Managed Identity (RBAC), VNet (network rules) [opcional]       │
│                                                                              │
│  📨 Service Bus                                                              │
│      └── Usa: Managed Identity (RBAC) [opcional]                             │
│                                                                              │
│  ⚡ Event Grid                                                               │
│      └── Usa: Managed Identity (RBAC), Service Bus (subscriptions) [opcional]│
│                                                                              │
│  🔴 Redis Cache                                                              │
│      └── Usa: VNet (Premium SKU only) [opcional]                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      RECURSOS COM DEPENDÊNCIAS OBRIGATÓRIAS                  │
│  (REQUEREM outros recursos para funcionar)                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  🗄️ SQL Server & Database                                                   │
│      └── REQUER: Managed Identity (output: admin_password)                   │
│      └── Usa: Key Vault (armazena senha), VNet (firewall rules) [opcional]   │
│      ⚠️  Key Vault depende do SQL para armazenar a senha gerada              │
│                                                                              │
│  🔐 Key Vault                                                                │
│      └── REQUER: SQL (se enable_sql=true, armazena sql-admin-password)       │
│      └── Usa: Managed Identity (RBAC) [opcional]                             │
│      ⚠️  depends_on = [module.sql] para evitar ciclo                         │
│                                                                              │
│  📦 Container Apps                                                           │
│      └── REQUER: Observability (Log Analytics workspace_id)                  │
│      └── Usa: VNet (infrastructure_subnet_id) [opcional]                     │
│      ⚠️  NÃO será criado se enable_observability = false                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Tabela de Dependências (Referência Rápida)

| Recurso | Depende de (OBRIGATÓRIO) | Usa (OPCIONAL) | Condição de Criação |
|---------|-------------------------|----------------|---------------------|
| Resource Group | - | - | Sempre criado |
| Managed Identity | Resource Group | - | Sempre criado |
| VNet Spoke | Resource Group | - | `enable_vnet = true` |
| Observability | Resource Group | - | `enable_observability = true` |
| Storage Account | Resource Group | Managed Identity, VNet | `enable_storage = true` |
| Service Bus | Resource Group | Managed Identity | `enable_service_bus = true` |
| Event Grid | Resource Group | Managed Identity, Service Bus | `enable_event_grid = true` |
| Redis Cache | Resource Group | VNet (Premium) | `enable_redis = true` |
| **SQL** | Resource Group, Managed Identity | VNet | `enable_sql = true` |
| **Key Vault** | Resource Group, SQL* | Managed Identity | `enable_key_vault = true` |
| **Container Apps** | Resource Group, **Observability** | VNet | `enable_container_apps = true AND enable_observability = true` |

> \* Key Vault depende do SQL apenas para armazenar a senha gerada. Se `enable_sql = false`, Key Vault é criado sem secrets.

### Validações Automáticas

O Terraform deve validar e alertar sobre dependências não satisfeitas:

```hcl
# Container Apps requer Observability
resource "null_resource" "validate_container_apps" {
  count = var.enable_container_apps && !var.enable_observability ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: Container Apps requires Observability (enable_observability = true)' && exit 1"
  }
}
```

### Exemplos de Uso

**Deploy Completo (todos os recursos):**
```hcl
# terraform.tfvars - Padrão, todos habilitados
name = "myplatform"
# Todos os enable_* são true por padrão
```

**Apenas Infraestrutura Base:**
```hcl
name = "myplatform"
enable_vnet           = true
enable_observability  = true
enable_key_vault      = false
enable_storage        = false
enable_service_bus    = false
enable_event_grid     = false
enable_sql            = false
enable_redis          = false
enable_container_apps = false
```

**Apenas Mensageria (Service Bus + Event Grid):**
```hcl
name = "myplatform"
enable_vnet           = false
enable_observability  = false
enable_key_vault      = false
enable_storage        = false
enable_service_bus    = true
enable_event_grid     = true
enable_sql            = false
enable_redis          = false
enable_container_apps = false
```

**Apenas Banco de Dados (SQL + Key Vault para senha):**
```hcl
name = "myplatform"
enable_vnet           = false
enable_observability  = false
enable_key_vault      = true   # Para armazenar a senha do SQL
enable_storage        = false
enable_service_bus    = false
enable_event_grid     = false
enable_sql            = true   # Requer Key Vault para senha
enable_redis          = false
enable_container_apps = false
```

**Container Apps (requer Observability):**
```hcl
name = "myplatform"
enable_vnet           = true   # Opcional mas recomendado
enable_observability  = true   # OBRIGATÓRIO para Container Apps
enable_key_vault      = false
enable_storage        = false
enable_service_bus    = false
enable_event_grid     = false
enable_sql            = false
enable_redis          = false
enable_container_apps = true
```

---

## REGRAS CRÍTICAS - LIÇÕES APRENDIDAS

### Configurações Obrigatórias

```
Região padrão: eastus2 (hardcoded, não passar na pipeline)
```

### Atributos Deprecated no Azure Provider 4.x - NÃO USAR:

| ❌ Deprecated | ✅ Usar em vez disso |
|--------------|---------------------|
| `enable_rbac_authorization` (Key Vault) | Removido - RBAC é padrão |
| `enable_authentication` (Redis) | Removido - Usar `active_directory_authentication_enabled` |
| `enable_https_traffic_only` (Storage) | `https_traffic_only_enabled` |
| `zone_redundant` (Service Bus) | `premium_messaging_partitions` |
| `enable_partitioning` (Service Bus Queue/Topic) | Removido - Controlado no namespace |
| `metric` (Diagnostic Settings) | `enabled_metric` |

### Recursos NÃO SUPORTADOS no Provider 4.x:

- `azurerm_servicebus_namespace_network_rule_set` - Não existe
- `redis_persistence` block no `azurerm_redis_cache` - Não suportado

### Event Grid - Atributos Diretos (NÃO usar blocos dinâmicos):

| Atributo | Correção |
|----------|----------|
| `service_bus_queue_endpoint_id` | Atributo direto, NÃO usar `dynamic` block |
| `service_bus_topic_endpoint_id` | Atributo direto, NÃO usar `dynamic` block |

```hcl
# ❌ ERRADO - Blocos dinâmicos
dynamic "service_bus_queue_endpoint_id" {
  for_each = var.service_bus_queue_id != null ? [1] : []
  content {
    service_bus_queue_endpoint_id = var.service_bus_queue_id
  }
}

# ✅ CORRETO - Atributo direto
service_bus_queue_endpoint_id = var.service_bus_queue_id
service_bus_topic_endpoint_id = var.service_bus_topic_id
```

### Provider Configuration

```hcl
provider "azurerm" {
  features {}  # OBRIGATÓRIO - Bloco vazio mas necessário
  subscription_id = var.subscription_id
}
```

### Key Vault - NUNCA Expor Dados Sensíveis

**REGRA ABSOLUTA:** O módulo Key Vault NÃO deve retornar valores de secrets nos outputs.

#### ❌ PROIBIDO - Outputs que expõem secrets:

```hcl
# NUNCA fazer isso - expõe valores sensíveis
output "secrets" {
  value = azurerm_key_vault_secret.secrets
}

output "secret_values" {
  value     = { for k, v in azurerm_key_vault_secret.secrets : k => v.value }
  sensitive = true  # Mesmo com sensitive, NÃO FAZER
}

output "sql_password" {
  value     = azurerm_key_vault_secret.sql_password.value
  sensitive = true  # PROIBIDO
}
```

#### ✅ PERMITIDO - Apenas metadata (IDs, nomes, URIs):

```hcl
output "id" {
  description = "ID do Key Vault"
  value       = azurerm_key_vault.main.id
}

output "vault_uri" {
  description = "URI do Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "secret_ids" {
  description = "IDs dos secrets criados (sem valores)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_uris" {
  description = "URIs dos secrets (para referência em outros recursos)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.versionless_id }
}
```

#### Padrão para Criar Secrets no Key Vault:

```hcl
# No módulo Key Vault - recebe secrets como variável sensível
variable "secrets" {
  description = "Map de secrets a serem criados"
  type        = map(string)
  default     = {}
  sensitive   = true  # OBRIGATÓRIO
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
}

# Output apenas dos IDs - NUNCA dos valores
output "secret_ids" {
  description = "IDs dos secrets criados"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}
```

#### No main.tf - Passando secrets para o módulo:

```hcl
module "key_vault" {
  source = "./modules/security/key-vault"
  
  # ... outras configurações ...
  
  secrets = var.enable_sql ? {
    "sql-admin-password" = module.sql[0].admin_password
  } : {}
}
```

**Resumo das Regras:**
1. ❌ NUNCA criar output com `.value` de secrets
2. ❌ NUNCA retornar o objeto completo `azurerm_key_vault_secret`
3. ✅ SEMPRE marcar variáveis de secrets como `sensitive = true`
4. ✅ APENAS expor `.id`, `.name`, `.versionless_id` nos outputs
5. ✅ Aplicações devem buscar secrets via Key Vault URI em runtime

---

## SQL Server - Configuração Automática

### Usuário e Senha

- **Usuário padrão**: `sql_admin` (NÃO passar na pipeline)
- **Senha**: Gerada automaticamente com `random_password`
- **Armazenamento**: Automático no Key Vault

```hcl
# Geração automática de senha
resource "random_password" "sql_admin" {
  length           = 16
  override_special = "!@#$%&*()-_=+[]{}<>:?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Usuário padrão
administrator_login = var.administrator_login != null ? var.administrator_login : "sql_admin"
administrator_login_password = random_password.sql_admin.result
```

### Azure AD Administrator - OPCIONAL

O bloco `azuread_administrator` deve ser dinâmico:

```hcl
dynamic "azuread_administrator" {
  for_each = var.azuread_admin_login != null && var.azuread_admin_object_id != null ? [1] : []
  content {
    login_username              = var.azuread_admin_login
    object_id                   = var.azuread_admin_object_id
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = var.azuread_authentication_only
  }
}
```

---

## Environment - PROIBIDO

**NÃO USAR** variável `environment` em nenhum lugar:
- Sem `environment` nas variáveis
- Sem `environment` nas tags
- Sem `environment` nos nomes de recursos
- Sem `environment` na pipeline

A plataforma é **ÚNICA** - identificada apenas por `name` + `location`.

---

## Pipeline - Input Único

A pipeline deve ter **APENAS UM INPUT OBRIGATÓRIO**:

```yaml
inputs:
  name:
    description: 'Name (team or product - lowercase alphanumeric)'
    required: true
    type: string
```

**NÃO incluir na pipeline:**
- ❌ `team` e `product` separados
- ❌ `environment`
- ❌ `location` (usar default)
- ❌ `sql_admin_login` / `sql_admin_object_id`


## Deploy - Configuração Padrão

### Secrets obrigatórios no GitHub Actions

Para autenticação no Azure durante o deploy, configure estes secrets no repositório:

- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`

### Autenticação via Variáveis de Ambiente (ARM_*)

**NÃO usar** `azure/login@v2` action. Use variáveis de ambiente no nível do job:

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      TF_VAR_name: ${{ inputs.name || 'paas' }}
    defaults:
      run:
        shell: bash
        working-directory: terraform
```

**Por que ARM_* ao invés de azure/login?**
- Terraform usa diretamente as variáveis `ARM_*`
- Evita problemas com OIDC/Federated Credentials
- Mais simples e compatível com Service Principal + Client Secret

### Backend do Terraform (Azure Storage)

O state remoto deve usar Storage Account padrão da plataforma com **autenticação via Azure AD**:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
    use_azuread_auth     = true  # OBRIGATÓRIO - Storage Account não aceita chaves
  }
}
```

**Por que `use_azuread_auth = true`?**
- A Storage Account `storagepaas` está configurada para **não aceitar autenticação por chave** (apenas Azure AD)
- Faz o Terraform usar as credenciais `ARM_*` (Azure AD/Service Principal) para acessar o state
- Evita o erro: `KeyBasedAuthenticationNotPermitted`

**Pré-requisito:** O Service Principal precisa ter a role **Storage Blob Data Contributor** na Storage Account `storagepaas`.

Na pipeline, o `terraform init` deve incluir:

```yaml
- name: Terraform Init
  run: |
    terraform init -input=false \
      -backend-config="resource_group_name=rg-paas" \
      -backend-config="storage_account_name=storagepaas" \
      -backend-config="container_name=tfstate" \
      -backend-config="key=${{ env.TF_VAR_name }}.terraform.tfstate" \
      -backend-config="use_azuread_auth=true"
```

Esses valores devem ser refletidos na pipeline de `terraform init`.

---

## Integração com Observability

Todos os recursos devem ter **Diagnostic Settings** quando `enable_observability = true`:

```hcl
resource "azurerm_monitor_diagnostic_setting" "resource_name" {
  count = var.enable_resource && var.enable_observability ? 1 : 0
  
  name                       = "diag-${module.naming.resource_name}"
  target_resource_id         = module.resource[0].id
  log_analytics_workspace_id = module.observability[0].log_analytics_id
  
  enabled_log {
    category = "CategoryName"
  }
  
  enabled_metric {  # NÃO usar 'metric'
    category = "AllMetrics"
  }
}
```

---

## Evitar Dependências Cíclicas

### Problema Comum: Key Vault ↔ SQL

**❌ ERRADO:**
```hcl
module "key_vault" {
  rbac_assignments = {
    sql_secrets_officer = {
      principal_id = module.sql[0].identity_principal_id  # CICLO!
    }
  }
}
```

**✅ CORRETO:**
```hcl
# RBAC separado, após ambos os módulos
resource "azurerm_role_assignment" "sql_key_vault_access" {
  count = var.enable_sql && var.enable_key_vault ? 1 : 0
  
  scope                = module.key_vault[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.sql[0].identity_principal_id
  
  depends_on = [module.sql, module.key_vault]
}
```

---

## Naming Convention

Padrão simplificado: `<prefix>-<name>-<location_abbr>`

```hcl
locals {
  name          = lower(var.name)
  location_abbr = lookup(local.location_abbreviations, var.location, substr(var.location, 0, 3))
  
  base_name_pattern = "${local.name}-${local.location_abbr}"
  
  resource_group    = "rg-${local.base_name_pattern}"
  key_vault         = "kv-${local.name}${local.location_abbr}"  # Sem hífens
  storage_account   = "st${local.name}${local.location_abbr}"   # Sem hífens
}
```

---

## Validação Obrigatória

Ao final, executar:

```bash
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.dev
```

**Só considerar completo quando:**
- ✅ `terraform init` - Success
- ✅ `terraform validate` - Success! The configuration is valid.
- ✅ `terraform plan` - Mostra recursos a serem criados (erro de auth Azure é esperado sem login)

---

## Estrutura de Pastas

```
terraform/
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars.example
└── modules/
    ├── foundation/
    │   ├── naming/
    │   └── resource-group/
    ├── networking/
    │   └── vnet-spoke/
    ├── security/
    │   ├── key-vault/
    │   └── managed-identity/
    └── workloads/
        ├── container-apps/
        ├── event-grid/
        ├── observability/
        ├── redis-cache/
        ├── service-bus/
        ├── sql/
        └── storage-account/
```

---

## Checklist Final

### Configuração Base
- [ ] Região padrão eastus2 (hardcoded)
- [ ] Sem `environment` em nenhum lugar
- [ ] Input único `name` na pipeline

### Feature Flags e Dependências
- [ ] Cada recurso tem `enable_<recurso>` variável
- [ ] Resource Group e Managed Identity sempre criados
- [ ] Container Apps valida `enable_observability = true`
- [ ] Key Vault usa `depends_on = [module.sql]`
- [ ] Recursos com `count` baseado em feature flags

### Recursos
- [ ] SQL com usuário padrão `sql_admin` e senha no Key Vault
- [ ] Todos os Diagnostic Settings com `enabled_metric`
- [ ] Sem atributos deprecated (Provider 4.x)
- [ ] Sem recursos não suportados
- [ ] Sem dependências cíclicas

### Validação
- [ ] `terraform init -backend=false` - Success
- [ ] `terraform validate` - Success
- [ ] Testar com todos os recursos habilitados
- [ ] Testar com recursos individuais
