# Export Discovery Runbook (Source Org)

## Purpose
Run credential-driven source org discovery and export artifacts for cross-org migration planning.

This workflow does not require manual source resource IDs as input. Operators provide source OAuth credentials and region/API host only.

## Required Inputs (Credential-Only)
- source_genesyscloud_oauthclient_id
- source_genesyscloud_oauthclient_secret
- source_genesyscloud_region (for example: us-east-1, eu-west-1, or an API host such as api.mypurecloud.com)

Accepted input names:
- Parameters: SourceOAuthClientId, SourceOAuthClientSecret, SourceRegion
- Env vars (lower or upper case):
  - source_genesyscloud_oauthclient_id or SOURCE_GENESYSCLOUD_OAUTHCLIENT_ID
  - source_genesyscloud_oauthclient_secret or SOURCE_GENESYSCLOUD_OAUTHCLIENT_SECRET
  - source_genesyscloud_region or SOURCE_GENESYSCLOUD_REGION

## Commands
Parameter invocation:

```powershell
./scripts/export-discovery.ps1 `
  -SourceOAuthClientId "<source-client-id>" `
  -SourceOAuthClientSecret "<source-client-secret>" `
  -SourceRegion "us-east-1"
```

Environment variable invocation:

```powershell
$env:SOURCE_GENESYSCLOUD_OAUTHCLIENT_ID = "<source-client-id>"
$env:SOURCE_GENESYSCLOUD_OAUTHCLIENT_SECRET = "<source-client-secret>"
$env:SOURCE_GENESYSCLOUD_REGION = "us-east-1"
./scripts/export-discovery.ps1
```

Help:

```powershell
./scripts/export-discovery.ps1 -Help
```

## Output Artifacts
Each run writes to:
- <repo-root>/exports/source/<timestamp>/

Path behavior:
- The script resolves output relative to its own location, so exports are written under the repository root regardless of the caller's current directory.
- The resolved absolute export directory is printed before discovery begins.

Artifacts produced:
- flows.json
- queues.json
- integrations.json
- integration_actions.json
- routing_skills.json
- routing_languages.json
- wrap_up_codes.json
- summary.json

summary.json includes generation metadata, source host, file list, and per-class counts.

## How Artifacts Feed Migration Planning
1. Use artifact files as the source of truth to update inventory and dependency mapping in migration-manifest.md.
2. Generate environment-specific substitutions from exported names/properties, not from manually entered source IDs.
3. Confirm Phase 3 pre-deploy readiness in implementation-plan.md using the generated summary and resource counts.

## Security Notes
- Do not commit secrets, tokens, or credential exports.
- Do not paste client secret values into logs or issue comments.
- The script does not print OAuth bearer tokens.
- Keep source credentials in secure env vars, secret stores, or CI secret managers.

## Verification Note
- In non-git environments, blueprint-change verification requires external source-control evidence.
