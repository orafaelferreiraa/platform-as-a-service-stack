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

taxonomia e convenções de nomenclatura dos recursos

limites e capacidades de cada serviço

suporte oficial a Managed Identity

padrões recomendados de arquitetura e segurança

Na etapa de Terraform
Consulte obrigatoriamente o MCP oficial do Terraform para:

design correto de módulos

uso de outputs e referências entre módulos

boas práticas de state, providers e dependências explícitas

Na etapa de CI/CD
Consulte obrigatoriamente o MCP oficial do GitHub para:

inputs de workflows

segurança de pipelines

padrões recomendados para GitHub Actions

Não invente nomenclaturas.
Não use padrões informais.
A nomenclatura fixa dos recursos deve seguir exclusivamente a taxonomia documentada pelo cloud provider.

Escopo da plataforma

A plataforma deve oferecer, de forma modular e composable, os seguintes recursos, respeitando ordem de prioridade e usabilidade:

VNet spoke
Managed Identity
Key Vault
Storage Account
Service Bus
Event Grid
Observability (Log Analytics + Application Insights)
Container Apps

Cada recurso deve poder ser criado de forma independente ou em conjunto com os demais, respeitando apenas dependências técnicas reais.

Managed Identity como padrão de identidade

Sempre que um serviço suportar Managed Identity, a plataforma deve:

Criar a Managed Identity correspondente
Referenciar explicitamente essa identidade no Terraform
Conceder permissões via RBAC ou policies adequadas
Evitar qualquer uso de secrets, connection strings sensíveis ou credenciais estáticas

A relação entre recursos e Managed Identity deve ser clara, rastreável e declarativa no código Terraform.

Exemplos de serviços que devem consumir Managed Identity quando suportado:

Container Apps
Key Vault (access via RBAC)
Storage Account
Service Bus
Event Grid (quando aplicável)

Princípios obrigatórios de arquitetura

Arquitetura baseada exclusivamente em Terraform modules reutilizáveis
Nenhum recurso deve ser criado fora de módulos
Módulos devem ser atômicos, claros e bem documentados
A plataforma deve permitir composição flexível de recursos
Evitar acoplamento rígido entre módulos
A ordem de provisionamento deve seguir a prioridade funcional dos recursos
Managed Identity deve ser o mecanismo padrão de autenticação entre serviços

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
Limites de tamanho e caracteres por tipo de recurso
Abreviações oficiais documentadas
Consistência entre recursos do mesmo produto

Não criar convenções próprias.
Sempre consultar a documentação oficial da Azure para definir a taxonomia.

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
Container Apps

O usuário deve conseguir:

Provisionar todos os recursos em uma única execução
Provisionar apenas um recurso específico
Provisionar recursos adicionais posteriormente sem impactar os existentes

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

Pense como engenheiro de plataforma criando uma infraestrutura base corporativa, reutilizável e segura, que será consumida por dezenas de times de produto com autonomia e previsibilidade.