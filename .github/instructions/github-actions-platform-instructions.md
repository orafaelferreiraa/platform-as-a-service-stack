---
name: "GitHub Actions Workflow Standards - Platform as a Service Stack"
description: "CI/CD pipeline patterns, Terraform automation, and deployment workflows for Platform Stack"
applyTo: "**/.github/workflows/*.{yml,yaml}"
---

# GitHub Actions Workflow Standards - Platform as a Service Stack

## MCP Integration - GitHub Operations
**Use GitHub MCP tools** for repository operations and workflow management:

### Available GitHub Tools
```bash
mcp_github_github_search_code                 # Search code across repositories
mcp_github_github_search_pull_requests        # Find PRs with specific criteria
mcp_github_github_create_or_update_file       # Create/update files remotely
mcp_github_github_create_pull_request         # Create PRs programmatically
mcp_github_github_create_branch               # Create new branches
mcp_github_github_fork_repository             # Fork repositories
mcp_github_github_request_copilot_review      # Request AI code reviews
```

**Pattern**: Before creating workflows, search existing patterns with `mcp_github_github_search_code` to maintain consistency.

---

## Platform Stack Workflow Architecture

### Repository Configuration
- **Repository**: platform-as-a-service-stack
- **Workflow Location**: `.github/workflows/`
- **Branch Protection**: main branch protected, requires PR approval
- **Secrets Required**: 
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`

### Workflow Categories
1. **Terraform Plan Workflow**: Validate changes on PR creation
2. **Terraform Apply Workflow**: Deploy infrastructure on manual trigger or push to main
3. **Validation Workflow**: Check code quality, anti-patterns, syntax

---

## Terraform Plan Workflow (Pull Request)

### Purpose
Validate Terraform changes and provide plan output as PR comment

### Implementation
```yaml
name: Terraform Plan - Platform Infrastructure

on:
  pull_request:
    branches:
      - main
    paths:
      - "terraform/**"
      - ".github/workflows/terraform-plan.yml"

permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    
    env:
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_USE_AZUREAD: true
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      
      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="resource_group_name=rg-paas" \
            -backend-config="storage_account_name=storagepaas" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=platform.terraform.tfstate" \
            -backend-config="use_azuread_auth=true"
      
      - name: Terraform Validate
        working-directory: terraform
        run: terraform validate
      
      - name: Terraform Format Check
        working-directory: terraform
        run: terraform fmt -check -recursive
      
      - name: Terraform Plan
        working-directory: terraform
        run: |
          terraform plan \
            -var="name=${{ github.event.inputs.platform_name || 'testplatform' }}" \
            -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}" \
            -var="enable_managed_identity=${{ github.event.inputs.enable_managed_identity || 'true' }}" \
            -var="enable_vnet=${{ github.event.inputs.enable_vnet || 'true' }}" \
            -var="enable_observability=${{ github.event.inputs.enable_observability || 'true' }}" \
            -var="enable_storage=${{ github.event.inputs.enable_storage || 'true' }}" \
            -var="enable_service_bus=${{ github.event.inputs.enable_service_bus || 'false' }}" \
            -var="enable_event_grid=${{ github.event.inputs.enable_event_grid || 'false' }}" \
            -var="enable_sql=${{ github.event.inputs.enable_sql || 'false' }}" \
            -var="enable_key_vault=${{ github.event.inputs.enable_key_vault || 'false' }}" \
            -var="enable_container_apps=${{ github.event.inputs.enable_container_apps || 'false' }}" \
            -no-color \
            -out=tfplan
      
      - name: Post Plan to PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('terraform/tfplan.txt', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Terraform Plan Output\n\n\`\`\`terraform\n${plan}\n\`\`\``
            });
```

### Key Features
- Runs on every PR to `main`
- Validates Terraform syntax and format
- Posts plan output as PR comment
- **Never applies changes** (read-only)

---

## Terraform Apply Workflow (Manual or Push)

### Purpose
Apply approved infrastructure changes to Azure

### Implementation
```yaml
name: Deploy Platform Infrastructure

on:
  push:
    branches:
      - main
    paths:
      - "terraform/**"
  workflow_dispatch:
    inputs:
      platform_name:
        description: 'Platform name (lowercase alphanumeric)'
        required: true
        type: string
      
      action:
        description: 'Terraform action'
        required: true
        type: choice
        options:
          - plan
          - apply
        default: 'plan'
      
      # Feature flags
      enable_managed_identity:
        description: 'Enable Managed Identity'
        type: boolean
        default: true
      
      enable_vnet:
        description: 'Enable VNet'
        type: boolean
        default: true
      
      enable_observability:
        description: 'Enable Observability (Log Analytics + App Insights)'
        type: boolean
        default: true
      
      enable_storage:
        description: 'Enable Storage Account'
        type: boolean
        default: true
      
      enable_service_bus:
        description: 'Enable Service Bus'
        type: boolean
        default: false
      
      enable_event_grid:
        description: 'Enable Event Grid'
        type: boolean
        default: false
      
      enable_sql:
        description: 'Enable SQL Server + Database'
        type: boolean
        default: false
      
      enable_key_vault:
        description: 'Enable Key Vault'
        type: boolean
        default: false
      
      enable_container_apps:
        description: 'Enable Container Apps (requires Observability)'
        type: boolean
        default: false

permissions:
  contents: read
  id-token: write

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    
    env:
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      ARM_USE_AZUREAD: true
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      
      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="resource_group_name=rg-paas" \
            -backend-config="storage_account_name=storagepaas" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=${{ github.event.inputs.platform_name || 'platform' }}.terraform.tfstate" \
            -backend-config="use_azuread_auth=true"
      
      - name: Terraform Plan
        working-directory: terraform
        run: |
          terraform plan \
            -var="name=${{ github.event.inputs.platform_name }}" \
            -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}" \
            -var="enable_managed_identity=${{ github.event.inputs.enable_managed_identity }}" \
            -var="enable_vnet=${{ github.event.inputs.enable_vnet }}" \
            -var="enable_observability=${{ github.event.inputs.enable_observability }}" \
            -var="enable_storage=${{ github.event.inputs.enable_storage }}" \
            -var="enable_service_bus=${{ github.event.inputs.enable_service_bus }}" \
            -var="enable_event_grid=${{ github.event.inputs.enable_event_grid }}" \
            -var="enable_sql=${{ github.event.inputs.enable_sql }}" \
            -var="enable_key_vault=${{ github.event.inputs.enable_key_vault }}" \
            -var="enable_container_apps=${{ github.event.inputs.enable_container_apps }}" \
            -out=tfplan
      
      - name: Terraform Apply
        if: github.event.inputs.action == 'apply' || github.event_name == 'push'
        working-directory: terraform
        run: terraform apply -auto-approve tfplan
      
      - name: Terraform Output
        if: success()
        working-directory: terraform
        run: terraform output -json > outputs.json
      
      - name: Upload Outputs
        if: success()
        uses: actions/upload-artifact@v4
        with:
          name: terraform-outputs
          path: terraform/outputs.json
```

### Key Features
- Manual trigger via `workflow_dispatch` with declarative inputs
- Automatic trigger on push to `main`
- Requires manual approval (production environment)
- All feature flags configurable via UI checkboxes
- Uploads outputs as artifacts

---

## Validation Workflow (Code Quality)

### Purpose
Detect anti-patterns and validate code standards

### Implementation
```yaml
name: Validate Platform Code

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  validate-anti-patterns:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Check for random_string/random_uuid
        run: |
          if grep -r "random_string\|random_uuid" terraform/modules/; then
            echo "ERROR: Found random_string or random_uuid in modules (use MD5 instead)"
            exit 1
          fi
      
      - name: Check role assignment names
        run: |
          if grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="; then
            echo "ERROR: Found role assignments without 'name' attribute (use uuidv5)"
            exit 1
          fi
      
      - name: Check null checks in count
        run: |
          if grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/; then
            echo "ERROR: Found null/empty checks in count conditions (use boolean flags only)"
            exit 1
          fi
      
      - name: Check for inter-module dependencies
        run: |
          if grep -n "module\\..*\\..*=" terraform/modules/ 2>/dev/null | grep -v "# This is OK"; then
            echo "ERROR: Found inter-module dependencies (orchestrate at root level)"
            exit 1
          fi
      
  terraform-validate:
    runs-on: ubuntu-latest
    
    env:
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      
      - name: Terraform Init
        working-directory: terraform
        run: |
          terraform init \
            -backend-config="resource_group_name=rg-paas" \
            -backend-config="storage_account_name=storagepaas" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=validation.terraform.tfstate" \
            -backend-config="use_azuread_auth=true"
      
      - name: Terraform Validate
        working-directory: terraform
        run: terraform validate
      
      - name: Terraform Format Check
        working-directory: terraform
        run: terraform fmt -check -recursive
```

### Key Features
- Detects all anti-patterns from instructions
- Validates Terraform syntax
- Checks code formatting
- Fails PR if violations found

---

## Workflow Best Practices

### Secret Management
**Use GitHub Secrets** - never hardcode credentials:

```yaml
env:
  # Azure authentication
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_USE_AZUREAD: true
```

**Required Secrets**:
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_TENANT_ID`: Azure AD tenant ID
- `AZURE_CLIENT_ID`: Service Principal client ID
- `AZURE_CLIENT_SECRET`: Service Principal client secret

### Conditional Execution

**Run jobs conditionally**:
```yaml
jobs:
  deploy-production:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    # ...
```

**Path-based triggers**:
```yaml
on:
  push:
    branches:
      - main
    paths:
      - "terraform/**"
      - ".github/workflows/terraform-apply.yml"
```

### Environment Protection

**Require manual approval for production**:
```yaml
jobs:
  terraform-apply:
    environment: production  # Requires approval
    runs-on: ubuntu-latest
    # ...
```

**Configure in Settings → Environments → production**:
- Required reviewers: 1-6 people
- Wait timer: 0-43200 minutes
- Deployment branches: Only protected branches

---

## Debugging Workflows

### Enable Debug Logging
**Set repository secrets**:
- `ACTIONS_STEP_DEBUG` = `true` (verbose step logging)
- `ACTIONS_RUNNER_DEBUG` = `true` (runner infrastructure logging)

### Workflow Outputs
**Capture outputs for debugging**:
```yaml
steps:
  - name: Terraform Plan
    working-directory: terraform
    id: plan
    run: terraform plan -out=tfplan
  
  - name: Show Plan
    run: echo "${{ steps.plan.outputs.stdout }}"
```

### Artifact Upload
**Save important files**:
```yaml
- name: Upload Plan
  uses: actions/upload-artifact@v4
  with:
    name: terraform-plan
    path: terraform/tfplan
    retention-days: 7
```

---

## Workflow Performance Optimization

### Caching Dependencies
**Cache Terraform plugins**:
```yaml
- name: Cache Terraform
  uses: actions/cache@v4
  with:
    path: |
      ~/.terraform.d/plugin-cache
      **/.terraform
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      ${{ runner.os }}-terraform-
```

### Concurrency Controls
**Prevent concurrent deployments**:
```yaml
concurrency:
  group: terraform-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false  # Wait for current deployment
```

---

## Common Workflow Errors

### Error: "Resource not accessible by integration"
**Cause**: Insufficient GitHub token permissions
**Solution**: Update workflow permissions:
```yaml
permissions:
  contents: write      # Read/write repo content
  pull-requests: write # Create/update PR comments
  id-token: write      # OIDC token for Azure
```

### Error: "Backend initialization required"
**Cause**: Missing `terraform init` or wrong backend config
**Solution**: Ensure init with correct backend config:
```yaml
- name: Terraform Init
  run: |
    terraform init \
      -backend-config="use_azuread_auth=true"
```

### Error: "No such file or directory: tfplan"
**Cause**: Plan output not saved correctly
**Solution**: Use `-out=tfplan` and reference in apply:
```yaml
- name: Terraform Plan
  run: terraform plan -out=tfplan

- name: Terraform Apply
  run: terraform apply tfplan  # Not -auto-approve
```

---

## MCP Usage in Workflows

### Before Creating New Workflow
```bash
# Search existing workflows
mcp_github_github_search_code(
  repo: "platform-as-a-service-stack",
  query: "terraform workflow_dispatch"
)

# Check similar patterns
mcp_github_github_search_code(
  repo: "platform-as-a-service-stack",
  query: "environment: production"
)
```

### Creating Pull Request with Workflow
```bash
# Create branch
mcp_github_github_create_branch(
  owner: "your-org",
  repo: "platform-as-a-service-stack",
  branch: "feature/new-workflow",
  from_branch: "main"
)

# Create/update workflow file
mcp_github_github_create_or_update_file(
  owner: "your-org",
  repo: "platform-as-a-service-stack",
  path: ".github/workflows/new-workflow.yml",
  content: "...",
  message: "Add new workflow",
  branch: "feature/new-workflow"
)

# Create PR
mcp_github_github_create_pull_request(
  owner: "your-org",
  repo: "platform-as-a-service-stack",
  title: "Add new workflow",
  body: "Description...",
  head: "feature/new-workflow",
  base: "main"
)
```

---

## GitHub Actions with Azure Authentication

### Service Principal Setup
```bash
# Create Service Principal
az ad sp create-for-rbac \
  --name "platform-stack-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>

# Output:
# {
#   "appId": "<client-id>",
#   "displayName": "platform-stack-github-actions",
#   "password": "<client-secret>",
#   "tenant": "<tenant-id>"
# }
```

### Add Secrets to GitHub
1. Go to Settings → Secrets and variables → Actions
2. Add repository secrets:
   - `AZURE_CLIENT_ID`: appId from above
   - `AZURE_CLIENT_SECRET`: password from above
   - `AZURE_TENANT_ID`: tenant from above
   - `AZURE_SUBSCRIPTION_ID`: your subscription ID

---

## File References

- **Terraform Plan Workflow**: [.github/workflows/terraform-plan.yml](../../.github/workflows/terraform-plan.yml)
- **Terraform Apply Workflow**: [.github/workflows/terraform-apply.yml](../../.github/workflows/terraform-apply.yml)
- **Validation Workflow**: [.github/workflows/validate.yml](../../.github/workflows/validate.yml)
- **Terraform Files**: [terraform/](../../terraform/)

---

## Complete Workflow Example

See [.github/workflows/deploy-infrastructure.yml](../../.github/workflows/deploy-infrastructure.yml) for complete implementation with:
- Feature flag inputs
- Manual approval
- Plan/apply separation
- Output artifacts
- Error handling
