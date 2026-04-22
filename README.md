# Solace Agent Mesh Kubernetes Toolkit

This repository is the cleaned source tree for building, deploying, and operating Solace Agent Mesh on Kubernetes.

It keeps only source-of-truth assets:
- reusable Codex skill bundle for SAM CI/CD
- current RFQ / operations / legal demo agent sources
- deployment manifests and seed data
- deployment and upgrade scripts
- migration, runtime, and hardening documentation

Generated state, backups, image tars, local databases, logs, and one-off verification files are intentionally excluded from Git and now go under `build/`.

## Repository layout

```text
.
├── deploy/
│   ├── hardening/      # source patch manifests and self-heal assets
│   └── rfq/            # agent configs, runtime manifests, prompts, project templates
├── docs/
│   ├── blueprints/
│   ├── migration/
│   ├── reference/
│   └── runbooks/
├── packages/
│   ├── custom-bedrock-legal-agent/
│   └── custom-joule-agent/
├── runtimes/
│   └── bedrock-london-local/
├── scripts/
│   ├── 00-07           # generic build/import/deploy helpers
│   ├── 10-22           # RFQ/demo/platform operations
│   └── lib.sh
└── skills/
    └── solace-agent-mesh-k8s-cicd/
```

## What to use first

### For another Codex agent
Use the skill bundle:
- [skills/solace-agent-mesh-k8s-cicd](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/skills/solace-agent-mesh-k8s-cicd)

It teaches another agent how to:
- classify SAM changes by control surface
- decide when YAML-only edits are enough
- decide when a new image is required
- version agent configs and runtime images safely
- upgrade core, gateways, and standalone agents in the right order
- handle secrets, RBAC, prompts, projects, and rollback

### For current demo source
- RFQ/ops agent package: [packages/custom-joule-agent](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-joule-agent)
- Bedrock legal plugin package: [packages/custom-bedrock-legal-agent](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/packages/custom-bedrock-legal-agent)
- Bedrock-compatible runtime: [runtimes/bedrock-london-local](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/runtimes/bedrock-london-local)

### For deployment config
- RFQ deploy config: [deploy/rfq](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/rfq)
- Hardening manifests: [deploy/hardening](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/deploy/hardening)

## Key scripts

### Generic helpers
- `./scripts/01_preflight.sh`
- `./scripts/02_build_image.sh`
- `./scripts/03_import_image_to_k3s.sh`
- `./scripts/04_create_db_bridge_secret.sh`
- `./scripts/05_deploy_agent.sh`
- `./scripts/06_verify_agent.sh`
- `./scripts/00_autodeploy_from_package.sh`

These now write generated outputs under `build/`, not into tracked source folders.

### RFQ / demo operations
- `./scripts/10_replace_rfq_stack.sh`
- `./scripts/11_seed_prompt_library.sh`
- `./scripts/12_apply_demo_enhancements.sh`
- `./scripts/19_test_rfp_scenarios.sh`
- `./scripts/21_deploy_operations_reuse.sh`
- `./scripts/22_harden_k8s1_demo.sh`

## Primary documentation
- Runtime inventory: [docs/reference/k8s1-runtime-inventory.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/reference/k8s1-runtime-inventory.md)
- Open-source to enterprise mapping: [docs/migration/open-source-to-k8s1-mapping.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/migration/open-source-to-k8s1-mapping.md)
- Windows handoff guide: [docs/migration/windows-open-source-yaml-to-enterprise-k8s-1.65.45.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/migration/windows-open-source-yaml-to-enterprise-k8s-1.65.45.md)
- Bedrock runtime runbook: [docs/runbooks/bedrock-london-local-bedrock-legal-agent.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/runbooks/bedrock-london-local-bedrock-legal-agent.md)
- K8s1 hardening runbook: [docs/runbooks/k8s1-demo-hardening.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/runbooks/k8s1-demo-hardening.md)
- Reuse scenario blueprint: [docs/blueprints/reuse-scenario-blueprint.md](/Users/raphaelcaillon/Documents/github/custom-tool-deployment/docs/blueprints/reuse-scenario-blueprint.md)

## Notes
- `.env` stays local and is ignored.
- `build/` is the only place for generated tar files, backups, and verification output.
- Environment-specific live values are intentionally not committed.
