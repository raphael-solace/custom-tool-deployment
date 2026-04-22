# Operations Reuse Showcase (Blueprint)

Goal: demonstrate agent reusability with minimal new code by composing existing SAP/PIM/Shipping capabilities into a second business project.

## Proposed additional agents

1. `OrderExceptionTriageAgent`
- Purpose: classify delayed or broken order incidents and propose recovery actions.
- Reuses: `SapJouleAgent`, `ShippingAgent`, `AcmeRetailPim`.
- Config template: [order-exception-triage-agent-config.yaml](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/order-exception-triage-agent-config.yaml)

2. `ReplenishmentPlannerAgent`
- Purpose: create 7-14 day replenishment plans with cost, lead-time, and stockout trade-offs.
- Reuses: `AcmeRetailPim`, `SapJouleAgent`, `ShippingAgent`.
- Config template: [replenishment-planner-agent-config.yaml](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/replenishment-planner-agent-config.yaml)

## Next agents worth adding

1. `ReturnsResolutionAgent`
- Purpose: handle damaged or returned goods, suggest refund/replacement/recovery paths.
- Reuses: `OrderExceptionTriageAgent`, `ShippingAgent`, `bedrock_legal_agent`.

2. `SupplierRiskAgent`
- Purpose: summarize supplier concentration, lead-time volatility, and sourcing fallback risk.
- Reuses: `SapJouleAgent`, `AcmeRetailPim`, future supplier scorecards.

3. `SLAComplianceAgent`
- Purpose: check delivery promises, escalation thresholds, and contractual exposure.
- Reuses: `ShippingAgent`, `bedrock_legal_agent`, project prompts/artifacts.

## Proposed second project

Template payload:
- [operations-reuse-project-template.json](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq/operations-reuse-project-template.json)

Notes:
- Prompt-library scenarios `OPS1` and `OPS2` are seeded by `scripts/11_seed_prompt_library.sh`.
- Lead agent for delayed-order recovery: `OrderExceptionTriageAgent`.
- Lead agent for replenishment planning: `ReplenishmentPlannerAgent`.
- Supporting reusable agents already in the environment: `SapJouleAgent`, `ShippingAgent`, `AcmeRetailPim`, `bedrock_legal_agent`.

## Suggested demo flow

1. Run `OPS1` for delayed order recovery.
2. Show severity classification, two recovery options, and customer impact.
3. Run `OPS2` for replenishment planning.
4. Compare cost, lead-time, and stockout-risk trade-offs.
