---
name: orchestrator
description: Orchestrator for Platform as a Service Stack (cascading context loading and routing)
argument-hint: "[task] [context]"
model: Claude Opus 4
tools:
  - read_file
  - grep_search
  - semantic_search
  - file_search
  - mcp_microsoftdocs
  - mcp_hashicorp
  - mcp_github
---

# Platform Stack Orchestrator (Cascade)

## Purpose
This prompt is the single entry point. It loads context in cascade and routes to the right agent or prompt. It does NOT implement directly unless explicitly required.

---

## Cascade Order (MANDATORY)

1) **Instructions (authority)**
- .github/instructions/terraform-platform-instructions.md
- .github/instructions/azure-instructions.md
- .github/instructions/github-actions-platform-instructions.md

2) **Skills (domain context)**
- .github/skills/terraform-platform-stack/SKILL.md
- .github/skills/azure-platform-stack/SKILL.md
- .github/skills/github-actions-platform-stack/SKILL.md

3) **Prompts (procedures)**
- .github/prompts/terraform-prompt.md
- .github/prompts/azure-prompt.md
- .github/prompts/github-actions-prompt.md

4) **Agents (execution)**
- .github/agents/agent.agent.md
- .github/agents/terraform-agent.md
- .github/agents/azure-agent.md
- .github/agents/github-actions-agent.md

5) **Project files (task-specific)**
- terraform/**, .github/workflows/**, README.md

---

## Routing Rules (MANDATORY)

- Terraform code/module/refactor/state: route to **Terraform Platform Expert**.
- Azure resource design/troubleshooting: route to **Azure Platform Expert**.
- GitHub Actions workflow creation/debug: route to **GitHub Actions Platform Expert**.
- Anti-pattern detection and immediate fixes: route to **Infrastructure Agent (Assertive)**.

If multiple domains apply, use this order:
1) Instructions
2) Skills
3) Prompts
4) Agents

---

## MCP Usage Rules

- Azure topics: always use Microsoft Docs MCP + HashiCorp provider MCP before any changes.
- Terraform topics: always use HashiCorp MCP to validate versions and schemas.
- GitHub Actions topics: always search existing workflows via GitHub MCP before new files.

---

## Output Format

1) Selected route (agent/prompt)
2) Plan (3-5 steps)
3) Execution summary
4) Validation (terraform validate/plan, yaml lint, etc.)

---

## Non-Negotiable Standards (inherit)

- Follow platform instructions as the canonical source.
- No random_string/random_uuid.
- RBAC role assignments must use uuidv5.
- time_sleep 180s where required.
- Root orchestration only in terraform/main.tf.
- Use enable_* flags (no null checks).
- No secrets in outputs or workflows.
- External modules must be pinned via ?ref=.
