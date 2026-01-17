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

Recursos a serem oferecidos (em ordem de dependência):

1. **Managed Identity** - Base para autenticação (required for Key Vault, Storage, Service Bus, Event Grid, SQL)
2. **VNet Spoke** - Rede privada (optional for Storage, Service Bus, SQL, Redis, Container Apps)
3. **Observability** - Log Analytics + App Insights (required for Container Apps, diagnostics)
4. **Key Vault** - Gestão de secrets (uses: Managed Identity | required for SQL password)
5. **Storage Account** - Armazenamento (uses: Managed Identity, VNet)
6. **Service Bus** - Mensageria (uses: Managed Identity)
7. **Event Grid** - Eventos (uses: Managed Identity)
8. **SQL Server & Database** - Banco de dados (uses: Managed Identity, Key Vault, VNet)
9. **Redis Cache** - Cache (uses: VNet)
10. **Container Apps** - Containers (requires: Observability | uses: VNet)

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

O state remoto deve usar Storage Account padrão da plataforma:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-paas"
    storage_account_name = "storagepaas"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
  }
}
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

- [ ] Região padrão eastus2
- [ ] Sem `environment` em nenhum lugar
- [ ] Input único `name` na pipeline
- [ ] SQL com usuário padrão e senha no Key Vault
- [ ] Todos os Diagnostic Settings com `enabled_metric`
- [ ] Sem atributos deprecated
- [ ] Sem recursos não suportados
- [ ] Sem dependências cíclicas
- [ ] `terraform validate` passando
