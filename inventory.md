# Phase 1: Genesys Cloud Cross-Org Resource Inventory (No AWS Dependency)

## Overview
This inventory defines the resource classes required for cross-org migration using Terraform.

## 1. Architect Flows
| Resource | Terraform Type | Module | Dependencies |
|---|---|---|---|
| Main call flow | `genesyscloud_flow` | `modules/deploy_flows/` | queues, integration actions |
| Reusable sub-flow(s) | `genesyscloud_flow` | `modules/deploy_flows/` | flows, queues |

## 2. Queues
| Resource | Terraform Type | Module | Dependencies |
|---|---|---|---|
| Service queues | `genesyscloud_routing_queue` | `modules/queues/` | users (optional members) |
| Queue memberships | queue membership blocks in queue resource | `modules/queues/` | user IDs |

## 3. Integrations and Data Actions
| Resource | Terraform Type | Module | Dependencies |
|---|---|---|---|
| Custom integration | `genesyscloud_integration` | `modules/data_actions/` | endpoint/auth values |
| Routing decision action | `genesyscloud_integration_action` | `modules/data_actions/` | integration |

## 4. Routing Skills/Languages
| Resource | Terraform Type | Module | Dependencies |
|---|---|---|---|
| Skills (optional) | `genesyscloud_routing_skill` | `modules/routing/` | none |
| Languages (optional) | `genesyscloud_routing_language` | `modules/routing/` | none |

## 5. Wrap-up Codes (Optional)
| Resource | Terraform Type | Module | Dependencies |
|---|---|---|---|
| Wrap-up codes | `genesyscloud_routing_wrapupcode` | `modules/wrap_up/` | none |

## 6. Users (Optional)
| Resource | Terraform Type | Module | Dependencies |
|---|---|---|---|
| Service/demo user | `genesyscloud_user` | `modules/users/` | roles (optional) |

## Dependency Graph
- Flow -> queues
- Flow -> integration action
- Queues -> users (optional membership)
- Routing module independent but may be referenced by queue configs

## Export Strategy
1. Export flows to file-based YAML/JSON under `modules/deploy_flows/`.
2. Export queues and integration actions to module-scoped HCL.
3. Capture immutable names (flow/action/queue names) and env-specific values separately.
