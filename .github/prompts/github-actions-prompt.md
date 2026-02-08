---
name: github-actions
description: Create or debug GitHub Actions workflows for Platform as a Service Stack
argument-hint: "[workflow-type] [action] [feature-flags]"
agent: GitHub Actions Platform Expert
model: Claude Sonnet 4
tools:
  - mcp_github
  - mcp_gitkraken
  - read_file
  - grep_search
  - semantic_search
  - create_file
  - file_search
---

# GitHub Actions Workflow Operations - Platform as a Service Stack

You are creating or debugging CI/CD workflows for **Platform as a Service Stack v3.0.0+**. **Always follow this workflow**:

## 1. Search Existing Patterns (MANDATORY)

Use MCP GitHub tools to find similar workflows:
```
mcp_github_github_search_code(
  repo: "platform-as-a-service-stack",
  query: "${input:workflow-type} .github/workflows"
)
```

## 2. Load Platform Stack Context Files
Read these instruction files:
- [.github/instructions/github-actions-platform-instructions.md](../instructions/github-actions-platform-instructions.md)
- [.github/copilot-instructions.md](../copilot-instructions.md)

## 3. Check Platform Stack Structure
Read project-specific context:
- Terraform: `terraform/backend.tf`, `terraform/variables.tf` (feature flags)
- State: Azure Blob Storage with `use_azuread_auth = true`
- Feature Flags: All `enable_*` variables in variables.tf

## 4. Platform Stack Workflow Architecture

### Fixed Configuration
- **Repository**: platform-as-a-service-stack
- **Branch**: main (protected, requires PR approval)
- **Runner**: ubuntu-latest (GitHub-hosted)
- **Terraform**: 1.9.0+
- **State Backend**: Azure Blob Storage (rg-paas/storagepaas/tfstate)

### Required Secrets
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## 5. Task Execution

### If Creating Terraform Plan Workflow (PR Validation):

**Purpose**: Validate changes and post plan output as PR comment

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
            -var="name=testplatform" \
            -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}" \
            -var="enable_container_registry=${{ github.event.inputs.enable_container_registry }}" \
            -var="container_registry_sku=${{ github.event.inputs.container_registry_sku }}" \
            -no-color \
            -out=tfplan
      
      - name: PoValidation Workflow (Anti-Pattern Detection):

**Purpose**: Detect anti-patterns and validate code standards

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
          if grep -n "module\\..*\\..*=" terraform/modules/ 2>/dev/null; then
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
**Common Platform Stack Workflow Errors**:

1. **"Backend initialization required"**
   - **Cause**: Missing `terraform init` or wrong backend config
   - **Solution**: Ensure init with `use_azuread_auth=true`

2. **"No such file or directory: tfplan"**
   - **Cause**: Plan output not saved correctly
   - **Solution**: Use `-out=tfplan` and reference in apply

3. **"Resource not accessible by integration"**
   - **Cause**: Insufficient GitHub token permissions
   - **Solution**: Add permissions block to workflow

4. **State locked**
   - **Cause**: Previous workflow didn't complete
   - **Solution**: Break lease in Azure Portal → Storage Account → Blob

## 6. Output Format

Provide:
- ✅ Complete workflow file (.github/workflows/*.yml)
- ✅ Feature flag inputs as checkboxes (for workflow_dispatch)
- ✅ Secret names and configuration instructions
- ✅ Environment protection setup (production requires approval)
- ✅ Anti-pattern validation steps
- ✅ Artifact upload for outputs
- ✅ Links to existing workflows: [terraform-plan.yml](.github/workflows/terraform-plan.yml)

## 7. Validation Checklist

Before suggesting workflow:
```bash
# YAML syntax validation
yamllint .github/workflows/*.yml

# Check for hardcoded secrets
grep -n "client_secret\|password\|token" .github/workflows/*.yml | grep -v "secrets\."

# Verify path filters
grep -n "paths:" .github/workflows/*.yml
```

---

## Example Usage

```
/github-actions terraform-plan
/github-actions terraform-apply --with-feature-flags
/github-actions validate-anti-patterns
/github-actions debug "Backend initialization required"
```

## Variables Available
- `${input:workflow-type}` - Type: terraform-plan, terraform-apply, validate
- `${input:action}` - Action: plan, apply
- `${input:feature-flags}` - Include feature flag checkboxes
- `${file}` - Current file path
- `${workspaceFolder}` - Workspace root

## Critical Platform Stack Rules
- ❌ NEVER hardcode secrets in workflows
- ❌ NEVER skip path filters (terraform/**)
- ❌ NEVER use concurrency cancel-in-progress for Terraform
- ❌ NEVER forget ARM_USE_AZUREAD=true environment variable
- ✅ ALWAYS search existing patterns via MCP first
- ✅ ALWAYS use ubuntu-latest runner
- ✅ ALWAYS add environment protection for production
- ✅ ALWAYS include anti-pattern validation
- ✅ ALWAYS use workflow_dispatch with declarative inputs
- ✅ ALWAYS upload outputs as artifacts

### Terraform Apply/Plan with Feature Flags (`workflow_dispatch` inputs)

#### Workflow Dispatch Inputs
```yaml
on:
  workflow_dispatch:
    inputs:
      enable_service_bus:
        description: "Enable Service Bus"
        type: boolean
        default: true
      enable_event_grid:
        description: "Enable Event Grid"
        type: boolean
        default: true
      enable_sql:
        description: "Enable SQL Database"
        type: boolean
        default: true
      enable_key_vault:
        description: "Enable Key Vault"
        type: boolean
        default: true
      enable_container_apps:
        description: "Enable Container Apps"
        type: boolean
        default: true
      enable_container_registry:
        description: "Enable Container Registry (ACR)"
        type: boolean
        default: true
      container_registry_sku:
        description: "Container Registry SKU"
        type: choice
        default: "Basic"
        options:
          - Basic
          - Standard
          - Premium
```

#### Feature Flag `-var` Flags
```yaml
          terraform plan \
            -var="enable_service_bus=${{ github.event.inputs.enable_service_bus }}" \
            -var="enable_event_grid=${{ github.event.inputs.enable_event_grid }}" \
            -var="enable_sql=${{ github.event.inputs.enable_sql }}" \
            -var="enable_key_vault=${{ github.event.inputs.enable_key_vault }}" \
            -var="enable_container_apps=${{ github.event.inputs.enable_container_apps }}" \
            -var="enable_container_registry=${{ github.event.inputs.enable_container_registry }}" \
            -var="container_registry_sku=${{ github.event.inputs.container_registry_sku }}" \
            -out=tfplan
```
      
      - name: Terraform Apply
        if: github.event.inputs.action == 'apply' || github.event_name == 'push'
        working-directory: terraform
        run: terraform apply -auto-approve tfplan
      
      - name: Upload Outputs
        if: success()
        uses: actions/upload-artifact@v4
        with:
          name: terraform-outputs
          path: terraform/outputs.json
```

### If Creating ArgoCD Workflow:

**Validation Workflow**:
```yaml
name: Validate ArgoCD Resources

on:
  pull_request:
    paths: ["resources.yaml", "apps/**"]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - uses: azure/setup-kubectl@v4

      - name: Validate YAML
        run: |
          for file in $(find . -name "*.yaml" -o -name "*.yml"); do
            kubectl --dry-run=client -f "$file" apply
          done

      - name: Check ArgoCD Metadata
        run: |
          grep -q "namespace:" argocd.yaml || exit 1
          grep -q "teams:" argocd.yaml || exit 1
```

### If Creating Application Build Workflow:

**Multi-stage deployment**:
```yaml
name: Deploy Application

on:
  push:
    branches: [develop, main]
    paths: ["src/**", "package.json"]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed: ${{ steps.detect.outputs.files }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      - id: detect
        run: |
          CHANGED=$(git diff --name-only HEAD^..HEAD | jq -R -s -c 'split("\n")[:-1]')
          echo "files=$CHANGED" >> $GITHUB_OUTPUT

  build-and-deploy:
    needs: detect-changes
    runs-on: "azure-identity"
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - run: npm ci
      - run: npm run build
      - name: Deploy
        run: az webapp deploy --name myapp --resource-group myrg
```

### If Debugging Workflow:

1. **Classify error**:
   - Runner offline → Check Settings → Actions → Runners
   - State locked → Azure Blob Storage lease
   - Auth failure → Verify secrets
   - Timeout → Add `timeout-minutes: 30`

2. **Enable debug logging**:
   - Set repository secrets:
     - `ACTIONS_STEP_DEBUG = true`
     - `ACTIONS_RUNNER_DEBUG = true`

3. **Provide solution** with:
   - Updated workflow YAML
   - Verification steps
   - Prevention measures

## 5. Workflow Standards

### Self-Hosted Runners:
- `runs-on: "azure"` - Terraform, Azure CLI, private resources
- `runs-on: "azure-identity"` - Azure Functions, MSI/OIDC
- `runs-on: "ubuntu-latest"` - Public operations

### Secret Management:
```yaml
env:
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Auto-provided
```

### Concurrency Control:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # For non-Terraform workflows
```

### Path Filters:
```yaml
on:
  push:
    paths:
      - "terraform/**"
      - "!terraform/modules/**"  # Exclude
```

## 6. Output Format

Provide:
- ✅ Complete workflow file(s) (.github/workflows/*.yml)
- ✅ Self-hosted runner labels
- ✅ Secret names and where to configure
- ✅ Testing instructions (workflow_dispatch)
- ✅ Performance optimizations (caching, parallelism)

---

## Example Usage

```
/github-actions terraform aks-terraform-template multi-tenant
/github-actions argocd alerting-argocd validation
/github-actions application user-management-system functions
/github-actions debug "runner offline"
```

## Variables Available
- `${input:workflow-type}` - Type: terraform, argocd, application, debug
- `${input:project-name}` - Project name
- `${input:multi-tenant}` - Flag for matrix strategy
- `${file}` - Current file path
- `${workspaceFolder}` - Workspace root

## Critical Rules
- ❌ NEVER hardcode secrets in workflows
- ❌ NEVER use GitHub-hosted runners for private Azure resources
- ❌ NEVER skip path filters (causes unnecessary runs)
- ❌ NEVER forget environment approvals for production
- ✅ ALWAYS search existing patterns via MCP first
- ✅ ALWAYS use correct self-hosted runner labels
- ✅ ALWAYS add concurrency controls for Terraform
- ✅ ALWAYS validate YAML syntax before suggesting
