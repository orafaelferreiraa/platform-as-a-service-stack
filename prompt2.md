Atue como um Engenheiro de Plataforma Sênior especializado em Azure, com experiência prática em criar plataformas internas para habilitar times de produto, inovação e aplicações.

Quero que você desenhe e gere a estrutura de uma plataforma de infraestrutura usando:

Azure como cloud provider
Terraform como Infrastructure as Code
GitHub Actions como pipeline de CI/CD

O objetivo é criar uma infraestrutura base de plataforma, consumida por times de produto como Infrastructure as a Service interna.
Essa plataforma não é foundation, landing zone ou arquitetura corporativa completa.
Ela existe para acelerar a criação de produtos, aplicações e inovações, oferecendo capacidades prontas, seguras e reutilizáveis.

Uso obrigatório de boas práticas oficiais (MCP)

Durante a geração da solução:

Na etapa de Azure
Consulte obrigatoriamente a documentação oficial da Azure (MCP Azure) para:

taxonomia e convenções oficiais de nomenclatura

limites, SKUs e modelos de consumo

suporte oficial a Managed Identity

padrões recomendados de segurança e arquitetura

Na etapa de Terraform
Consulte obrigatoriamente o MCP oficial do Terraform para:

design correto de módulos reutilizáveis

organização de código

referências entre módulos e outputs

boas práticas de state, providers e dependências

Na etapa de CI/CD
Consulte obrigatoriamente o MCP oficial do GitHub para:

design de workflows

inputs declarativos

segurança e manutenção de pipelines GitHub Actions

Não invente padrões.
Não use práticas desatualizadas.
Sempre priorize recomendações oficiais.

Escopo da plataforma

A plataforma deve oferecer, de forma modular e composable, os seguintes recursos, respeitando ordem de prioridade e usabilidade:

VNet spoke
Managed Identity
Key Vault
Storage Account
Service Bus
Event Grid
Observability (Log Analytics + Application Insights)
SQL Server
SQL Database
Redis Cache
Container Apps

Cada recurso deve poder ser criado de forma independente ou em conjunto com os demais, respeitando apenas dependências técnicas reais.

Managed Identity como padrão de autenticação

Sempre que um serviço suportar Managed Identity, a plataforma deve:

Criar a Managed Identity correspondente
Referenciar explicitamente essa identidade entre módulos Terraform
Conceder permissões via RBAC apropriado
Evitar uso de usuários, senhas ou secrets estáticos

Os seguintes recursos devem obrigatoriamente considerar Managed Identity quando suportado:

Container Apps
Key Vault (RBAC-based access)
Storage Account
Service Bus
Event Grid
SQL Server / SQL Database (Azure AD authentication)

Redis Cache deve ser tratado conforme suporte oficial atual do serviço.

Princípios obrigatórios de arquitetura

Arquitetura baseada exclusivamente em Terraform modules reutilizáveis
Nenhum recurso deve ser criado fora de módulos
Módulos devem ser atômicos, claros e bem documentados
A plataforma deve permitir composição flexível de recursos
Evitar acoplamento rígido entre módulos
A ordem de provisionamento deve seguir a prioridade funcional
Managed Identity deve ser o mecanismo padrão de autenticação

Requisitos de arquitetura

Separação lógica de responsabilidades entre:

foundation
networking
security
workloads

Essa separação deve existir apenas como organização estrutural e conceitual.

Uso de remote state do Terraform no Azure, utilizando Storage Account como backend, seguindo recomendações oficiais.

Naming e taxonomia oficial

A plataforma deve aceitar UM ÚNICO INPUT obrigatório, representando a identidade do produto.

Esse input encapsula:

nome do time
nome do produto

Todos os nomes de recursos devem ser gerados automaticamente a partir desse input, respeitando:

Convenções oficiais de naming da Azure
Abreviações documentadas por tipo de recurso
Limites de caracteres e regras específicas
Consistência entre todos os recursos do mesmo produto

Não criar convenções próprias.
Sempre consultar a documentação oficial do cloud provider para definir a taxonomia.

Pipeline CI/CD como interface da plataforma

Criar uma pipeline em GitHub Actions que funcione como interface única de consumo da plataforma.

Essa pipeline deve:

Aceitar um único input obrigatório representando time e produto

Esse input deve ser propagado automaticamente para:

Variáveis Terraform
Naming dos recursos
Tags
Identidade lógica do provisionamento

A pipeline deve aceitar um checklist de recursos, permitindo que o usuário selecione quais capacidades deseja provisionar, respeitando a seguinte ordem:

VNet spoke
Managed Identity
Key Vault
Storage Account
Service Bus
Event Grid
Observability
SQL Server
SQL Database
Redis Cache
Container Apps

O usuário deve conseguir:

Provisionar todos os recursos em uma única execução
Provisionar apenas um recurso específico
Provisionar novos recursos posteriormente sem impactar os existentes

Requisitos técnicos da pipeline

GitHub Actions
Execução de terraform fmt, terraform validate e terraform plan
Pipeline genérica, sem lógica hardcoded por time ou produto
Todas as decisões de provisionamento devem vir de inputs declarativos
Uso explícito de referências entre módulos Terraform
Adoção rigorosa das boas práticas recomendadas pelo MCP do GitHub

Outputs esperados

Explicação textual da arquitetura da plataforma
Estrutura de repositórios recomendada
Estrutura de pastas do Terraform
Exemplos conceituais de:

módulos Terraform
backend.tf
providers.tf
workflow do GitHub Actions

Lista de boas práticas adotadas
Lista de armadilhas comuns a evitar

Não simplifique demais.
Não trate isso como tutorial.
Não inclua conceitos fora do escopo definido.

Pense como engenheiro de plataforma criando uma infraestrutura base, reutilizável e segura, que será consumida por dezenas de times de produto com autonomia, previsibilidade e sem fricção.