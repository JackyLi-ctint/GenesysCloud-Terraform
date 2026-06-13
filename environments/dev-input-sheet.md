# Target Dev Input Sheet (Credential-Only)

Purpose: collect only credentials needed to authenticate source/target orgs for automated export and migration.

## Required User Inputs

- Source org OAuth client ID: `GENESYSCLOUD_OAUTHCLIENT_ID_SOURCE`
- Source org OAuth client secret: `GENESYSCLOUD_OAUTHCLIENT_SECRET_SOURCE`
- Target dev OAuth client ID: `GENESYSCLOUD_OAUTHCLIENT_ID_DEV`
- Target dev OAuth client secret: `GENESYSCLOUD_OAUTHCLIENT_SECRET_DEV`

## Not Required From User

- Manual resource IDs
- Manual queue/flow/integration IDs
- Per-resource mapping IDs

These are discovered from source export artifacts and mapped automatically by name and dependency graph.

## Optional Inputs (Only If Needed)

- Target test/prod OAuth credentials for later promotion phases
- Integration secret values only when source exports redact secure fields

## Completion Checklist

- [ ] Source OAuth credentials provided in secret store
- [ ] Target dev OAuth credentials provided in secret store
- [ ] No credentials committed to git
- [ ] Export/discovery step enabled for resource mapping
