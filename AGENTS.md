# AGENTS

Purpose: Help AI coding agents work effectively in this repository for Terraform Genesys infrastructure tasks.

## Scope
- Primary domain: Terraform for Genesys Cloud style infrastructure automation.
- Primary files: all *.tf, *.tfvars, and module directories.
- Focus scenario: cross-org resource migration using environment promotion (dev -> test -> prod as applicable).

## Default Workflow
1. Terraform Genesys Planner writes phased plan in markdown.
2. Terraform Genesys Implementor executes phases and updates code.
3. Terraform Genesys Reviewer validates and tests migration safety.
4. Promotion pattern follows blueprint-style gating: deploy to target dev org, run platform checks, then promote to target test org.
5. If reviewer finds issues, tasks go back to implementor for fixes.
6. Repeat implementor and reviewer cycle until reviewer passes.

## Agent Roles
- Terraform Genesys Planner: orchestration and phased markdown plan.
- Terraform Genesys Implementor: code changes and validation execution.
- Terraform Genesys Reviewer: quality gate, testing, and fix-loop trigger.

## Commands Agents Should Use
- Format: terraform fmt -recursive
- Validate: terraform validate
- Init (if needed): terraform init
- Plan: terraform plan -out=tfplan
- Show plan: terraform show tfplan

## Cross-Org Migration Guardrails
- Use per-org credentials and variables; never reuse source-org secrets in target orgs.
- Keep org-specific values in variables/tfvars or CI environment variables, not hardcoded in module code.
- Prefer remote state with separate workspaces per environment/org (for example prefix-based workspace naming).
- Require a reviewer gate after dev deployment checks before promotion to next org/environment.
- Avoid auto-approve apply in normal workflows; allow apply only on explicit user approval.

## Safety Rules
- Never run terraform apply automatically unless explicitly requested by the user.
- Never run terraform destroy unless explicitly requested by the user.
- Treat state as sensitive. Do not expose state content in chat output.
- Redact any secret-like values from logs, plans, and examples.

## Conventions
- Keep each module focused on one responsibility.
- Prefer explicit variable and output definitions in every module.
- Use descriptive names for resources, variables, and outputs.
- Keep provider and backend configuration explicit and reviewable.

## Suggested Structure
- modules/: reusable module implementations
- environments/: per-environment variable files or stacks
- root stack files: minimal orchestration layer

## Pull Request Expectations For Agents
- Explain what changed and why.
- Include validation output summary (fmt and validate at minimum).
- Call out any potential drift, replacement, or blast-radius risks.

## Unknowns
This repository is currently empty. As project files are added, update this file with:
- Provider/version pinning strategy
- Remote state backend details
- CI pipeline commands
- Naming/tagging conventions
