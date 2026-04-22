# Bedrock London Local + Bedrock Legal Agent Runbook

This runbook deploys an in-cluster Bedrock-compatible runtime (`bedrock-london-local`) and a standalone SAM agent (`bedrock-legal-agent`) wired through `sam_bedrock_agent`.
Internal SAM identifier uses `bedrock_legal_agent` (underscore) to satisfy SAM naming validation.

## Prerequisites

1. `.env` configured for SSH access to `emeak8s1`.
2. Local tools: `docker`, `kubectl`, `helm`, `jq`, `ssh`, `scp`, `expect`.
3. SAM core stack already running in namespace `default`.

## 1) Build runtime image

```bash
./scripts/13_build_bedrock_london_local_image.sh
```

## 2) Import + deploy runtime service

```bash
./scripts/14_deploy_bedrock_london_local.sh
```

## 3) Build/import SAM image with bedrock plugin module

```bash
./scripts/15_build_import_bedrock_legal_agent_image.sh
```

## 4) Deploy standalone SAM agent release

```bash
./scripts/16_deploy_bedrock_legal_agent.sh
```

## 5) Verify runtime + SAM integration

```bash
./scripts/17_verify_bedrock_london_local_and_agent.sh
```

Verification report is written to:
- `build/verification-bedrock-london-local-and-agent.txt`

## Optional direct contract check from laptop

```bash
kubectl -n default port-forward svc/bedrock-london-local 18000:8000
```

In another shell:

```bash
curl -X POST http://localhost:18000/invoke-agent \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "bdrklgl01",
    "agentAliasId": "ldnlocal1",
    "sessionId": "legaldemo01",
    "inputText": "What time is it and what is 2+2?"
  }'
```

Expected response shape:

```json
{
  "completion": {
    "text": "...",
    "sessionId": "legaldemo01",
    "agentId": "bdrklgl01",
    "agentAliasId": "ldnlocal1"
  },
  "trace": null
}
```
