# Migration Manifest: SOURCE_ORG -> TARGET_ORG (Cross-Org Only)

## Resource Mapping Table
| # | Source Resource | Terraform Type | Target Dev | Target Test | Target Prod | Immutable? | Variable Substitution | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | MainFlow | `genesyscloud_flow` | CrossOrgMainFlow | CrossOrgMainFlow | CrossOrgMainFlow | Yes | `var.flow_name`, `var.flow_filepath` | Flow logic promoted consistently |
| 2 | Support Queue | `genesyscloud_routing_queue` | Support | Support | Support | Yes | `var.queue_names` | Queue naming stable across envs |
| 3 | Sales Queue | `genesyscloud_routing_queue` | Sales | Sales | Sales | Yes | `var.queue_names` | Queue naming stable across envs |
| 4 | Billing Queue | `genesyscloud_routing_queue` | Billing | Billing | Billing | Yes | `var.queue_names` | Queue naming stable across envs |
| 5 | RouteDecisionAction | `genesyscloud_integration_action` | RouteDecisionAction | RouteDecisionAction | RouteDecisionAction | Yes | `var.integration_action_name`, endpoint/auth vars | Action naming stable across envs |
| 6 | CrossOrgIntegration | `genesyscloud_integration` | CrossOrgIntegration | CrossOrgIntegration | CrossOrgIntegration | Yes | `var.integration_name` | Integration naming stable across envs |
| 7 | Skills (optional) | `genesyscloud_routing_skill` | env-specific | env-specific | env-specific | No | `var.skill_names` | Optional by environment |
| 8 | Languages (optional) | `genesyscloud_routing_language` | env-specific | env-specific | env-specific | No | `var.language_names` | Optional by environment |
| 9 | Wrap-up Codes (optional) | `genesyscloud_routing_wrapupcode` | env-specific | env-specific | env-specific | No | `var.create_wrap_up_codes`, `var.wrap_up_codes` | Optional by environment |
| 10 | Service User (optional) | `genesyscloud_user` | env-specific | env-specific | env-specific | No | `var.create_user`, `var.user_*` | Optional by environment |

## Required Per-Environment Variables
- `genesyscloud_oauthclient_id`
- `genesyscloud_oauthclient_secret` (sensitive)
- `genesyscloud_region`
- `integration_endpoint_url`
- `integration_auth_value` (sensitive)

## Optional Per-Environment Variables
- `queue_names`
- `skill_names`
- `language_names`
- `create_user` and `user_*`
- `create_wrap_up_codes` and `wrap_up_codes`

## Promotion Safety Checks
1. No replacement of immutable flow/action/queue names unless explicitly approved.
2. No secrets in code, outputs, or logs.
3. Workspace and credentials match target environment.
4. Reviewer PASS before promotion.
