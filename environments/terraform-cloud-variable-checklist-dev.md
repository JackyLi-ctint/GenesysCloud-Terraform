# Terraform Cloud Variable Checklist (Target Dev)

Workspace: `genesys_migration_dev`

## Terraform Variables (HCL)

Set these in Terraform Cloud workspace variables with secrets marked sensitive.

### Sensitive = true

- `genesyscloud_oauthclient_secret`
- `source_genesyscloud_oauthclient_secret` (for export phase)

### Sensitive = false

- `genesyscloud_oauthclient_id`
- `source_genesyscloud_oauthclient_id` (for export phase)
- `genesyscloud_region`
- `source_genesyscloud_region` (for export phase)

## Workflow Rule

- Do not require users to provide resource IDs.
- Use source-org export/discovery to generate resource inventory and dependency mappings.
- Build migration artifacts from discovered resources, then plan against target dev.

## Terraform Cloud Environment Variables (optional pattern)

Use this only if your pipeline prefers environment variables:

- `TF_VAR_genesyscloud_oauthclient_secret` (sensitive)
- `TF_VAR_source_genesyscloud_oauthclient_secret` (sensitive)
- `TF_VAR_genesyscloud_oauthclient_id`
- `TF_VAR_source_genesyscloud_oauthclient_id`
- `TF_VAR_genesyscloud_region`
- `TF_VAR_source_genesyscloud_region`

## Validation Gate

Before running export/plan:

- [ ] Sensitive vars are masked in Terraform Cloud
- [ ] Source and target OAuth vars are present
- [ ] No manual resource-ID inputs are required
- [ ] Export/discovery completed for source resources
