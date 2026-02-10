---
name: github-actions
description: Create or debug GitHub Actions workflows for Platform as a Service Stack
argument-hint: "[workflow-type] [action] [feature-flags]"
agent: GitHub Actions Platform Expert
model: Claude Opus 4
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

## 3. Check Platform Stack Structure
Read project-specific context:
- Terraform: `terraform/backend.tf`, `terraform/variables.tf` (feature flags)
- State: Azure Blob Storage with `use_azuread_auth = true`
- Feature Flags: All `enable_*` variables in variables.tf

## 4. Task Execution

### If Creating Terraform Plan Workflow (PR Validation):
1. Trigger on `pull_request` to `main` with `paths: ["terraform/**"]`
2. Set permissions: `contents: read`, `pull-requests: write`, `id-token: write`
3. Configure ARM environment variables from secrets (include `ARM_USE_AZUREAD: true`)
4. Steps: Checkout → Setup Terraform → Init (with backend config) → Validate → Format Check → Plan → Post PR Comment
5. Refer to skill file for complete YAML template

### If Creating Validation Workflow (Anti-Pattern Detection):
1. Trigger on `pull_request` and `push` to `main`
2. Check for: `random_string`/`random_uuid`, missing role assignment names, null checks in count, inter-module dependencies
3. Run `terraform validate` and `terraform fmt -check`
4. Refer to skill file for complete YAML template

### If Creating Terraform Apply Workflow:
1. Use `workflow_dispatch` with feature flag boolean inputs
2. Map inputs to `-var` flags in terraform plan/apply
3. Include environment protection for production
4. Upload terraform outputs as artifacts
5. Refer to skill file for complete YAML template

### If Creating ArgoCD Workflow:
1. Trigger on `pull_request` with `paths: ["resources.yaml", "apps/**"]`
2. Validate YAML with `kubectl --dry-run`
3. Check ArgoCD metadata (namespace, teams)
4. Refer to skill file for complete YAML template

### If Creating Application Build Workflow:
1. Detect changes with `git diff`
2. Multi-stage: detect-changes → build-and-deploy
3. Refer to skill file for complete YAML template

### If Debugging Workflow:
1. **Classify error**: Runner offline → Runners settings; State locked → Azure Blob lease; Auth failure → Verify secrets; Timeout → Add `timeout-minutes: 30`
2. **Enable debug logging**: Set `ACTIONS_STEP_DEBUG = true` and `ACTIONS_RUNNER_DEBUG = true`
3. **Provide solution** with: Updated workflow YAML, verification steps, prevention measures

### Common Platform Stack Workflow Errors:

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

## 5. Output Format

Provide:
- ✅ Complete workflow file (.github/workflows/*.yml)
- ✅ Feature flag inputs as checkboxes (for workflow_dispatch)
- ✅ Secret names and configuration instructions
- ✅ Environment protection setup (production requires approval)
- ✅ Anti-pattern validation steps
- ✅ Artifact upload for outputs
- ✅ Links to existing workflows: [terraform-plan.yml](.github/workflows/terraform-plan.yml)

## 6. Validation Checklist

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
