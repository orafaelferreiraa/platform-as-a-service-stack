---
name: github-actions-platform-stack
description: GitHub Actions CI/CD specialist for Platform as a Service Stack v3.0.0+. Expert in Terraform workflows with feature flag inputs, anti-pattern validation, manual approval workflows, and GitHub-hosted runners. Always searches existing workflow patterns via GitHub MCP before creating to maintain consistency.
---

# GitHub Actions Platform Stack Specialist

## Overview

This skill provides expert guidance for creating, debugging, and optimizing GitHub Actions workflows for the **Platform as a Service Stack v3.0.0+**. It specializes in Terraform plan/apply workflows with declarative feature flag inputs, anti-pattern detection, environment protection, and artifact management.

## Critical Platform Stack Workflow Patterns

### Fixed Configuration

- **Repository**: platform-as-a-service-stack
- **Branch**: main (protected, requires PR approval)
- **Runner**: ubuntu-latest (GitHub-hosted)
- **Terraform Version**: 1.9.0+
- **State Backend**: Azure Blob (rg-paas/storagepaas/tfstate)

### Required GitHub Secrets

```
AZURE_SUBSCRIPTION_ID    - Azure subscription ID
AZURE_TENANT_ID          - Azure AD tenant ID
AZURE_CLIENT_ID          - Service principal client ID
AZURE_CLIENT_SECRET      - Service principal client secret
```

### Workflow 1: Terraform Plan (PR Validation)

**Purpose**: Validate Terraform changes on PRs, post plan as comment

```yaml
name: Terraform Plan - Platform Infrastructure

on:
  pull_request:
    branches:
      - main
    paths:
      - "terraform/**"

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
      ARM_USE_AZUREAD: true  # CRITICAL
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
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
      
      - name: Terraform Plan
        working-directory: terraform
        run: |
          terraform plan \
            -var="name=testplatform" \
            -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}" \
            -no-color \
            -out=tfplan
```

### Workflow 2: Terraform Apply (Deployment with Feature Flags)

**Purpose**: Deploy infrastructure with declarative feature flag checkboxes

```yaml
name: Deploy Platform Infrastructure

on:
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
      
      # Feature flags as checkboxes
      enable_managed_identity:
        description: 'Enable Managed Identity'
        type: boolean
        default: true
      
      enable_vnet:
        description: 'Enable VNet'
        type: boolean
        default: true
      
      enable_observability:
        description: 'Enable Observability'
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
        description: 'Enable SQL Server'
        type: boolean
        default: false
      
      enable_key_vault:
        description: 'Enable Key Vault'
        type: boolean
        default: false
      
      enable_container_apps:
        description: 'Enable Container Apps'
        type: boolean
        default: false

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
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.0
      
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
        if: github.event.inputs.action == 'apply'
        working-directory: terraform
        run: terraform apply -auto-approve tfplan
```

### Workflow 3: Validate Anti-Patterns

**Purpose**: Detect Platform Stack anti-patterns in PR

```yaml
name: Validate Platform Code

on:
  pull_request:
    branches:
      - main

jobs:
  validate-anti-patterns:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Check for random_string/random_uuid
        run: |
          if grep -r "random_string\|random_uuid" terraform/modules/; then
            echo "ERROR: Found random_string or random_uuid (use MD5 instead)"
            exit 1
          fi
      
      - name: Check role assignment names
        run: |
          if grep -n "azurerm_role_assignment" terraform/modules -r | grep -v "name ="; then
            echo "ERROR: Found role assignments without 'name' (use uuidv5)"
            exit 1
          fi
      
      - name: Check null checks in count
        run: |
          if grep -n "!= null\|!= \"\"\|== null\|== \"\"" terraform/; then
            echo "ERROR: Found null checks in count (use boolean flags only)"
            exit 1
          fi
```

## Common Debugging Scenarios

### 1. "Backend initialization required"

**Cause**: Missing `use_azuread_auth=true` in init

**Solution**:
```yaml
- name: Terraform Init
  run: |
    terraform init \
      -backend-config="use_azuread_auth=true"  # CRITICAL
```

### 2. "Key based authentication is not permitted"

**Cause**: Missing `ARM_USE_AZUREAD=true` environment variable

**Solution**:
```yaml
env:
  ARM_USE_AZUREAD: true  # Required for Storage Account without keys
```

### 3. State locked

**Cause**: Previous workflow didn't complete

**Solution**: Break lease in Azure Portal → Storage Account → Blob → Break Lease

### 4. Workflow timeout

**Cause**: RBAC propagation + large plan

**Solution**:
```yaml
jobs:
  terraform-apply:
    timeout-minutes: 60  # Increase from default 30
```

- Creating Terraform Plan workflows for PR validation
- Implementing Terraform Apply workflows with feature flag checkboxes
- Adding anti-pattern validation workflows (detect random_string, null checks, etc.)
- Debugging Azure authentication failures (ARM_USE_AZUREAD)
- Setting up environment protection with manual approval (production)
- Managing feature flag inputs as workflow_dispatch parameters
- Handling Terraform state backend initialization (use_azuread_auth)
- Implementing artifact upload for Terraform outputs
- Troubleshooting workflow timeout or state lock issues

## MANDATORY: MCP Integration Workflow

**BEFORE creating ANY new workflow, you MUST execute this workflow:**

### Step 1: Search Existing Patterns (REQUIRED)

```
Use mcp_github_github_search_code:
- Organization: stefanini-applications
- Query: ".github/workflows <workflow-type>"
- Purpose: Find similar existing workflows to maintain consistency

Example queries:
- ".github/workflows terraform plan"
- ".github/workflows argocd sync"
- ".github/workflows azure functions"
```

**Why this is critical:**
- Maintains consistency across repositories
- Reuses proven patterns
- Avoids reinventing existing solutions
- Ensures correct runner labels and secret names

### Step 2: Review Project Structure (REQUIRED)

```
Use read_file to understand project context:

For Terraform projects:
- Read: backend.tf (state configuration)
- Read: cluster-config/**/*.tfvars (multi-tenant configs)
- Read: providers.tf (provider aliases)

For ArgoCD projects:
- Read: argocd.yaml (metadata and teams)
- Read: resources.yaml (root application manifests)
- Read: apps/**/* (application directory structure)

For Application projects:
- Read: package.json, requirements.txt, pom.xml (build config)
- Read: Dockerfile (containerization)
- Read: deployment manifests (K8s YAML)
```

### Step 3: Validate GitHub MCP Tools (OPTIONAL)

```
Use mcp_github tools for automation:
- mcp_github_github_create_or_update_file: Create/update workflow files
- mcp_github_github_create_pull_request: Create PR with workflow changes
- mcp_github_github_create_branch: Create feature branch
- mcp_github_github_request_copilot_review: Request AI code review
```

## Critical Organizational Standards

### Self-Hosted Runners (CRITICAL)

**Organization:** `stefanini-applications`

**Runner labels and their purpose:**

```yaml
# Azure self-hosted runner with full access
runs-on: "azure"
# Use for:
# - Terraform operations
# - Azure CLI commands
# - Private network access (AKS, internal resources)
# - Azure Blob Storage (state files)

# Azure runner with Managed Identity/OIDC
runs-on: "azure-identity"
# Use for:
# - Azure Functions deployment
# - Managed Identity authentication
# - Azure-native service deployments

# GitHub-hosted runner
runs-on: "ubuntu-latest"
# Use for:
# - Public operations (no Azure resources)
# - Code validation (lint, format checks)
# - Documentation generation
```

**Runner capabilities (Azure self-hosted):**
- Pre-installed: Terraform, Azure CLI, kubectl, helm, PowerShell
- Network: Access to private AKS clusters, internal DNS, firewall-protected resources
- Authentication: Service Principal credentials in environment variables
- Storage: Azure Blob Storage access for Terraform state

**CRITICAL RULE:** NEVER use GitHub-hosted runners (`ubuntu-latest`) for:
- Terraform operations on private infrastructure
- Accessing private AKS clusters
- Deploying to internal Azure resources

### Workflow Categories and Patterns

#### 1. Terraform Workflows

**Two-workflow pattern (MANDATORY):**

1. **PR Workflow** - Validation only (never applies)
2. **Push/Merge Workflow** - Applies changes

**terraform-pr.yaml:**
```yaml
name: Terraform PR

on:
  pull_request:
    branches:
      - main
      - master
    paths:
      - "**/*.tf"
      - "**/*.tfvars"
      - ".github/workflows/terraform-*.yaml"

jobs:
  terraform-plan:
    runs-on: "azure"  # Self-hosted runner

    strategy:
      matrix:
        tenant: [na, sophie, woopi]
        environment: [dev, qa, prod]
      fail-fast: false  # Continue other environments if one fails

    env:
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.0"

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="key=${{ matrix.tenant }}-${{ matrix.environment }}.tfstate"

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: |
          terraform plan \
            -var-file="cluster-config/common/main.tfvars" \
            -var-file="cluster-config/specific/${{ matrix.tenant }}/${{ matrix.environment }}.tfvars" \
            -out=tfplan

      - name: Comment PR with Plan
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          script: |
            const output = `#### Terraform Plan 📖 \`${{ matrix.tenant }}-${{ matrix.environment }}\`
            <details><summary>Show Plan</summary>

            \`\`\`terraform
            ${{ steps.plan.outputs.stdout }}
            \`\`\`

            </details>`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });
```

**terraform-apply.yaml:**
```yaml
name: Terraform Apply

on:
  push:
    branches:
      - main
      - master
    paths:
      - "**/*.tf"
      - "**/*.tfvars"
  workflow_dispatch:  # Allow manual triggering

jobs:
  # Dev environment - auto-deploy
  terraform-apply-dev:
    runs-on: "azure"
    environment: development  # GitHub environment for tracking

    concurrency:
      group: terraform-${{ github.ref }}-dev
      cancel-in-progress: false  # NEVER cancel Terraform applies

    strategy:
      matrix:
        tenant: [na, sophie, woopi]
      fail-fast: false

    env:
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}

    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.0"

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="key=${{ matrix.tenant }}-dev.tfstate"

      - name: Terraform Apply
        run: |
          terraform apply -auto-approve \
            -var-file="cluster-config/common/main.tfvars" \
            -var-file="cluster-config/specific/${{ matrix.tenant }}/dev.tfvars"

  # Production environment - requires approval
  terraform-apply-prod:
    needs: terraform-apply-dev
    runs-on: "azure"
    environment: production  # Requires manual approval

    concurrency:
      group: terraform-${{ github.ref }}-prod
      cancel-in-progress: false

    strategy:
      matrix:
        tenant: [na, sophie, woopi]
      fail-fast: false

    env:
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}

    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.9.0"

      - name: Terraform Init
        run: |
          terraform init \
            -backend-config="key=${{ matrix.tenant }}-prod.tfstate"

      - name: Terraform Apply
        run: |
          terraform apply -auto-approve \
            -var-file="cluster-config/common/main.tfvars" \
            -var-file="cluster-config/specific/${{ matrix.tenant }}/prod.tfvars"
```

#### 2. ArgoCD Workflows

**Validation workflow:**
```yaml
name: Validate ArgoCD Resources

on:
  pull_request:
    branches:
      - main
    paths:
      - "argocd.yaml"
      - "resources.yaml"
      - "apps/**/*.yaml"
      - "apps/**/*.yml"

jobs:
  validate-yaml:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install kubectl
        uses: azure/setup-kubectl@v4

      - name: Validate YAML syntax
        run: |
          # Find all YAML files and validate
          find . -name "*.yaml" -o -name "*.yml" | while read file; do
            echo "Validating $file"
            kubectl --dry-run=client -f "$file" apply || exit 1
          done

      - name: Check ArgoCD metadata
        run: |
          # Verify required fields in argocd.yaml
          grep -q "namespace:" argocd.yaml || { echo "Missing namespace"; exit 1; }
          grep -q "teams:" argocd.yaml || { echo "Missing teams"; exit 1; }

      - name: Validate CODEOWNERS
        run: |
          if [ -f CODEOWNERS ]; then
            echo "CODEOWNERS file found"
            cat CODEOWNERS
          else
            echo "Warning: CODEOWNERS file missing"
          fi
```

**Sync status workflow:**
```yaml
name: Update ArgoCD Sync Status

on:
  push:
    branches:
      - main
    paths:
      - "apps/**"

jobs:
  update-sync-status:
    runs-on: "azure"

    steps:
      - uses: actions/checkout@v4

      - name: Update README with sync status
        run: |
          # Generate sync status table
          echo "## Sync Status" > sync-status.md
          echo "| Application | Status | Last Sync |" >> sync-status.md
          echo "|-------------|--------|-----------|" >> sync-status.md

          # Query ArgoCD for status (requires argocd CLI)
          argocd app list --output json | jq -r '.[] | "| \(.name) | \(.status.sync.status) | \(.status.operationState.finishedAt) |"' >> sync-status.md

      - name: Commit status update
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add sync-status.md
          git commit -m "Update ArgoCD sync status" || exit 0
          git push
```

#### 3. Application Build and Deploy

**Multi-stage deployment:**
```yaml
name: Build and Deploy Application

on:
  push:
    branches:
      - develop
      - main
    paths:
      - "src/**"
      - "package.json"
      - "Dockerfile"
  workflow_dispatch:

env:
  ACR_NAME: naacr
  IMAGE_NAME: myapp

jobs:
  # Detect what changed
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      has_code_changes: ${{ steps.filter.outputs.code }}
      has_config_changes: ${{ steps.filter.outputs.config }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            code:
              - 'src/**'
              - 'package.json'
            config:
              - 'k8s/**'
              - 'deployment/**'

  # Build and push Docker image
  build:
    needs: detect-changes
    if: needs.detect-changes.outputs.has_code_changes == 'true'
    runs-on: "azure-identity"

    steps:
      - uses: actions/checkout@v4

      - name: Login to ACR
        run: |
          az acr login --name ${{ env.ACR_NAME }}

      - name: Build and push image
        run: |
          VERSION=$(git rev-parse --short HEAD)
          IMAGE_TAG=${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:${VERSION}
          IMAGE_TAG_LATEST=${{ env.ACR_NAME }}.azurecr.io/${{ env.IMAGE_NAME }}:latest

          docker build -t ${IMAGE_TAG} -t ${IMAGE_TAG_LATEST} .
          docker push ${IMAGE_TAG}
          docker push ${IMAGE_TAG_LATEST}

          echo "IMAGE_TAG=${IMAGE_TAG}" >> $GITHUB_ENV

      - name: Output image tag
        id: image
        run: echo "tag=${{ env.IMAGE_TAG }}" >> $GITHUB_OUTPUT

    outputs:
      image_tag: ${{ steps.image.outputs.tag }}

  # Deploy to dev
  deploy-dev:
    needs: build
    runs-on: "azure"
    environment: development

    steps:
      - uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v4

      - name: Deploy to AKS
        run: |
          az aks get-credentials --resource-group na-rg-prod --name na-aks-dev

          kubectl set image deployment/myapp \
            myapp=${{ needs.build.outputs.image_tag }} \
            -n devops

          kubectl rollout status deployment/myapp -n devops

  # Deploy to prod (requires approval)
  deploy-prod:
    needs: [build, deploy-dev]
    runs-on: "azure"
    environment: production  # Manual approval required

    steps:
      - uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v4

      - name: Deploy to AKS
        run: |
          az aks get-credentials --resource-group na-rg-prod --name na-aks-prod

          kubectl set image deployment/myapp \
            myapp=${{ needs.build.outputs.image_tag }} \
            -n production

          kubectl rollout status deployment/myapp -n production
```

### Secret Management

**Required GitHub Secrets (set at organization or repository level):**

**Azure authentication:**
```
AZURE_SUBSCRIPTION_ID      - Azure subscription ID
AZURE_TENANT_ID            - Azure AD tenant ID
AZURE_CLIENT_ID            - Service principal client ID
AZURE_CLIENT_SECRET        - Service principal client secret
```

**Multi-tenant secrets (if needed):**
```
NA_SUBSCRIPTION_ID         - North America subscription
SOPHIE_SUBSCRIPTION_ID     - Sophie tenant subscription
WOOPI_SUBSCRIPTION_ID      - WoopiAI subscription

# Repeat for TENANT_ID, CLIENT_ID, CLIENT_SECRET per tenant
```

**Usage in workflows:**
```yaml
env:
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
```

**CRITICAL:** NEVER hardcode secrets in workflow files or commit them to git.

### Workflow Optimization

**Path filters (reduce unnecessary runs):**
```yaml
on:
  push:
    paths:
      - "terraform/**"           # Include
      - "!terraform/modules/**"  # Exclude
      - "**/*.tf"                # All Terraform files
      - "!**/*.md"               # Exclude docs
```

**Concurrency control:**
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # For non-critical workflows

# For Terraform (NEVER cancel mid-apply):
concurrency:
  group: terraform-${{ github.ref }}-${{ matrix.environment }}
  cancel-in-progress: false  # CRITICAL
```

**Caching dependencies:**
```yaml
# Node.js
- uses: actions/setup-node@v4
  with:
    node-version: "20"
    cache: "npm"  # Automatic caching

# Python
- uses: actions/setup-python@v5
  with:
    python-version: "3.11"
    cache: "pip"

# Terraform
- name: Cache Terraform providers
  uses: actions/cache@v4
  with:
    path: ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
```

**Conditional job execution:**
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'  # Only on main branch
    runs-on: "azure"
    steps:
      - name: Deploy only on weekdays
        if: github.event.schedule == '0 9 * * 1-5'
        run: echo "Deploying"
```

## Common Debugging Scenarios

### 1. Runner Offline

**Symptoms:**
- Workflow stuck on "Waiting for a runner"
- Message: "No online runners found"

**Resolution:**
1. Check runner status: Settings → Actions → Runners
2. Verify runner service: On Azure VM, check service status
3. Restart runner service if needed
4. Check network connectivity from runner to GitHub

### 2. Authentication Failure

**Symptoms:**
- "Error: building account: could not acquire access token"
- "az login" failures

**Resolution:**
```yaml
# Verify secrets are set correctly
- name: Debug auth (REMOVE IN PRODUCTION)
  run: |
    echo "Client ID: ${ARM_CLIENT_ID:0:8}..."  # Show first 8 chars only
    # NEVER echo full secret

# Test authentication
- name: Verify Azure access
  run: |
    az login --service-principal \
      --username $ARM_CLIENT_ID \
      --password $ARM_CLIENT_SECRET \
      --tenant $ARM_TENANT_ID

    az account show
```

### 3. Terraform State Lock

**Symptoms:**
- "Error: Error locking state"
- Workflow times out

**Resolution:**
```yaml
- name: Check state lock
  if: failure()
  run: |
    az storage blob show \
      --account-name stapplicationsautomation \
      --container-name tfstate \
      --name ${{ matrix.tenant }}-${{ matrix.environment }}.tfstate \
      --query "properties.lease"

# Manual intervention required - break lease in Azure Portal or CLI
```

### 4. Workflow Timeout

**Symptoms:**
- Workflow exceeds time limit and cancels

**Resolution:**
```yaml
jobs:
  terraform-plan:
    runs-on: "azure"
    timeout-minutes: 30  # Increase from default 360

    steps:
      - name: Long-running step
        timeout-minutes: 15  # Per-step timeout
        run: terraform plan
```

### 5. Enable Debug Logging

**For detailed troubleshooting:**

Set repository secrets:
```
ACTIONS_STEP_DEBUG = true
ACTIONS_RUNNER_DEBUG = true
```

Then re-run workflow to get detailed logs.

## Response Format

When providing workflow solutions:

1. **Analysis**: Understand the requirement and workflow type
2. **Existing patterns**: Show which workflows were consulted via MCP
3. **Complete workflow**: Full YAML file with comments
4. **Secrets required**: List of GitHub secrets to configure
5. **Runner requirements**: Which self-hosted runner to use
6. **Testing**: How to test the workflow (workflow_dispatch, dry-run)
7. **Optimization**: Performance tips (caching, path filters, parallelism)
8. **Troubleshooting**: Common issues and solutions

## Key Reminders

- ✅ ALWAYS search existing workflows via MCP before creating new ones
- ✅ ALWAYS use correct self-hosted runner labels
- ✅ ALWAYS add path filters to reduce unnecessary runs
- ✅ ALWAYS use concurrency control for Terraform (cancel-in-progress: false)
- ✅ ALWAYS add environment approvals for production deployments
- ✅ ALWAYS validate YAML syntax before committing
- ❌ NEVER hardcode secrets in workflows
- ❌ NEVER use GitHub-hosted runners for private Azure resources
- ❌ NEVER cancel Terraform applies mid-execution
- ❌ NEVER forget to set timeout limits for long-running jobs
