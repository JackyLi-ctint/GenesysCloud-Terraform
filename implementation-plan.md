# Implementation Plan: Genesys Cloud Cross-Org Resource Migration (No AWS Dependency)

## Goal
Migrate Genesys Cloud resources from a source organization to target organizations using Terraform with promotion gates.

Primary migration scope includes:
- Architect call flows
- Dependent resources: queues, integration actions, routing skills/languages, wrap-up codes, optional service users
- CI/CD promotion model: target dev validation before target test (and target prod if required)

## Assumptions
- Terraform with the Genesys Cloud provider is the migration engine.
- Source and target organizations use separate OAuth clients and credentials.
- Remote state is available (Terraform Cloud recommended) with separate workspaces per environment/org.
- Secrets are stored in secure variables (Terraform Cloud and/or CI secrets), never hardcoded.
- Reviewer gate is mandatory before promotion beyond target dev.
- No AWS-specific components are required for this migration scope.

## Org Mapping Matrix (Source and Target Orgs)
| Role | Org Name | Region/API Host | Terraform Workspace | Credential Set | Notes |
|---|---|---|---|---|---|
| Source | SOURCE_ORG | SOURCE_REGION / SOURCE_API_HOST | source-readonly | GENESYSCLOUD_OAUTHCLIENT_ID_SOURCE, GENESYSCLOUD_OAUTHCLIENT_SECRET_SOURCE | Used for inventory/export only |
| Target Dev | TARGET_DEV_ORG | TARGET_DEV_REGION / TARGET_DEV_API_HOST | genesys_migration_dev | GENESYSCLOUD_OAUTHCLIENT_ID_DEV, GENESYSCLOUD_OAUTHCLIENT_SECRET_DEV | First deployment target |
| Target Test | TARGET_TEST_ORG | TARGET_TEST_REGION / TARGET_TEST_API_HOST | genesys_migration_test | GENESYSCLOUD_OAUTHCLIENT_ID_TEST, GENESYSCLOUD_OAUTHCLIENT_SECRET_TEST | Promotion target after dev pass |
| Target Prod (optional) | TARGET_PROD_ORG | TARGET_PROD_REGION / TARGET_PROD_API_HOST | genesys_migration_prod | GENESYSCLOUD_OAUTHCLIENT_ID_PROD, GENESYSCLOUD_OAUTHCLIENT_SECRET_PROD | Promote only after test pass |

## Phase 1: Inventory and Export Strategy
1. Inventory source resources and dependency graph:
- **Flows**: Architect call flows, reusable task/menu references
- **Queues**: Queue names, ACW settings, skill/language requirements, queue members
- **Integrations**: Data actions/custom integrations and secure headers
- **Routing**: Call routing structures, skills, languages
- **Wrap-up codes**: Post-call handling outcomes
- **Other dependencies**: Users (for queue members), roles, default fallback targets

2. Export resources with the Genesys provider:
- Export flows to YAML/JSON files under `modules/deploy_flows/`.
- Export queue and integration resources into module-scoped HCL.
- Document resource IDs and cross-references for dependency mapping.

3. Identify parameterizable values:
- **Environment-specific**: endpoints, memberships, routing targets, org-specific IDs
- **Org-agnostic**: flow logic, queue names, integration action names
- **Secrets**: OAuth and integration auth values as sensitive vars

4. Create migration manifest:
- List each source resource ID, source name, target name, and env substitution.
- Mark immutable names vs env-specific values.

Deliverables:
- inventory.md
- migration-manifest.md
- module-local flow export files in `modules/deploy_flows/`

## Phase 2: Parameterization and Module Preparation
1. Build or adapt modules:
- `modules/deploy_flows`: `genesyscloud_flow`
- `modules/queues`: `genesyscloud_routing_queue`, membership handling
- `modules/data_actions`: `genesyscloud_integration`, `genesyscloud_integration_action`
- `modules/routing`: `genesyscloud_routing_skill`, `genesyscloud_routing_language`
- `modules/users` (optional): `genesyscloud_user`
- `modules/wrap_up` (optional): wrap-up code resources

2. Externalize environment values:
- region/API host, integration endpoint/auth, OAuth values
- keep in tfvars, Terraform Cloud vars, and CI secrets

3. Harden migration safety:
- remove demo-only hardcoded credentials
- enforce sensitive vars
- use separate workspaces per target environment

Deliverables:
- parameterized Terraform modules and root config
- env tfvars examples
- validated scaffold (`fmt` + `validate`)

## Phase 3: Target Dev Deployment and Platform Tests
1. Pre-deploy checks:
- terraform fmt -recursive
- terraform init
- terraform validate
- terraform plan -out=tfplan (target dev workspace)
- terraform show tfplan

2. Deploy to target dev (only with explicit approval).
3. Run platform tests in target dev:
- flow discoverable/published
- queues exist and are reachable
- integration action callable and returns expected routing target

4. Reviewer gate:
- syntax/plan risk/platform checks/secrets checks all pass

Deliverables:
- dev validation report
- platform test evidence
- reviewer pass/fail decision

## Phase 4: Promotion After Reviewer Pass
1. Promote same artifact to target test workspace.
2. Re-run validation and plan review in target test.
3. Deploy only after reviewer pass from dev stage.
4. Repeat for target prod if required.

Promotion rule:
- No promotion if reviewer gate fails.

## Validation and Risk Checks
- Flag replacements on flows, queues, and integration actions before apply.
- Verify secrets are not exposed in code, outputs, or logs.
- Verify correct workspace selected before plan/apply.
- Compare plan blast radius against migration manifest scope.

## Baseline Iteration Loop (Cross-Org-Only Enforcement)
Run this loop at the end of each phase and before any promotion:
1. Scope sweep:
- Search active scaffold files (exclude reference blueprint folder) for out-of-scope terms and modules.
- Out-of-scope examples: AWS-specific integrations, email-route/classifier artifacts, stale legacy module references.
2. Baseline corrections:
- Remove or refactor any out-of-scope artifacts back to the cross-org baseline.
- Keep integration and routing patterns provider-agnostic within Genesys Cloud scope.
3. Validation pass:
- terraform fmt -recursive
- terraform init -backend=false (when module graph changes)
- terraform validate
4. Reviewer checkpoint:
- Reviewer must explicitly confirm "cross-org-only baseline preserved" before next phase/promotion.

Baseline acceptance criteria per iteration:
- Active root scaffold contains no email-route/classifier module wiring.
- Active Terraform/docs contain no AWS-coupled implementation dependencies.
- Phase deliverables remain consistent with inventory and migration manifest.

## Rollback Considerations
- Keep previous known-good flow YAML/module versions tagged.
- Use workspace-scoped rollback plans for affected environment only.
- Pause promotion if partial failure occurs and remediate first.

## Delegation Workflow (Planner -> Implementor -> Reviewer)
1. Planner updates this phased plan and scope.
2. Implementor executes one phase at a time and reports file/command outcomes.
3. Reviewer validates and either passes or returns fix list.
4. Repeat implementor/reviewer loop until reviewer passes.

## Current Status and Next Actions

### Current Status
- Phase 1 complete: inventory and migration manifest are documented.
- Phase 2 complete: cross-org-only module scaffold is parameterized and validated.
- Baseline loop complete for latest iteration: out-of-scope local artifacts removed and Terraform validation passed.
- Current execution point: ready to start Phase 3 pre-deploy checks for target dev.

### Phase 3 Next Actions (Execution Checklist)
1. Populate target dev deployment inputs (required before plan):
- GENESYSCLOUD_OAUTHCLIENT_ID_SOURCE
- GENESYSCLOUD_OAUTHCLIENT_SECRET_SOURCE
- GENESYSCLOUD_OAUTHCLIENT_ID_DEV
- GENESYSCLOUD_OAUTHCLIENT_SECRET_DEV
- Source and target region/API host values

2. Prepare target dev variable set:
- Run source export/discovery using provider-aligned export to collect resources and dependency graph.
- Command reference (provider export alignment): `./scripts/export-discovery.ps1 -SourceOAuthClientId "<source-client-id>" -SourceOAuthClientSecret "<source-client-secret>" -SourceRegion "<source-region-or-api-host>"`
- Generate migration artifacts from provider export outputs (no manual resource-ID entry).

3. Run Phase 3 pre-deploy checks in target dev workspace:
- terraform fmt -recursive
- terraform init
- terraform validate
- terraform plan -out=tfplan
- terraform show tfplan

4. Reviewer gate for Phase 3 pre-deploy:
- Confirm cross-org-only baseline preserved.
- Confirm no unexpected replacements or blast-radius drift.
- Confirm no secrets exposure in output.

### Promotion Readiness Rule
- Do not proceed to any deploy or promotion step until Phase 3 pre-deploy checks and reviewer gate both pass.

### Input Policy
- Users provide credentials and environment endpoints, not individual resource IDs.
- Resource mapping is produced from automated source export/discovery artifacts.
