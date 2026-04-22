#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

NAMESPACE="${NAMESPACE:-default}"
RUNTIME_NAME="${RUNTIME_NAME:-bedrock-london-local}"
AGENT_RELEASE="${AGENT_RELEASE:-bedrock-legal-agent}"
RUNTIME_URL="${RUNTIME_URL:-http://bedrock-london-local.default.svc.cluster.local:8000}"
VERIFY_FILE="${VERIFY_FILE:-$BUILD_DIR/verification-bedrock-london-local-and-agent.txt}"

log "Running runtime and SAM verification"
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Verify runtime and agent rollouts"
  run_remote "kubectl -n ${NAMESPACE} rollout status deployment/${RUNTIME_NAME} --timeout=300s"
  run_remote "kubectl -n ${NAMESPACE} rollout status deployment/${AGENT_RELEASE} --timeout=300s"

  echo
  echo "== Runtime workloads =="
  run_remote "kubectl -n ${NAMESPACE} get deploy,svc,pod -l app.kubernetes.io/name=${RUNTIME_NAME} -o wide"

  echo
  echo "== Agent workloads =="
  run_remote "kubectl -n ${NAMESPACE} get deploy,pod -l app.kubernetes.io/instance=${AGENT_RELEASE} -o wide"

  echo
  echo "== Runtime /invoke-agent + AWS invoke_agent contract =="
  run_remote "POD=\$(kubectl -n ${NAMESPACE} get pod -l app.kubernetes.io/instance=quote-planning-agent -o jsonpath='{.items[0].metadata.name}'); \
kubectl -n ${NAMESPACE} exec -i \"\$POD\" -c sam -- python - <<'PY'
import json
import urllib.request
import boto3

runtime_url = '${RUNTIME_URL}'

payload = {
    'agentId': 'bdrklgl01',
    'agentAliasId': 'ldnlocal1',
    'sessionId': 'legaldemo01',
    'inputText': 'What time is it and what is 2+2?',
}
req = urllib.request.Request(
    runtime_url + '/invoke-agent',
    data=json.dumps(payload).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST',
)
with urllib.request.urlopen(req, timeout=30) as resp:
    body = json.loads(resp.read().decode('utf-8'))

assert 'completion' in body and 'text' in body['completion'], body
print(json.dumps({'invoke_agent_http': 'ok', 'completion_preview': body['completion']['text'][:120]}))

client = boto3.client(
    'bedrock-agent-runtime',
    region_name='us-east-1',
    aws_access_key_id='demoAccessKey',
    aws_secret_access_key='demoSecretKey',
    endpoint_url=runtime_url,
)
stream_resp = client.invoke_agent(
    agentId='bdrklgl01',
    agentAliasId='ldnlocal1',
    sessionId='legaldemo01',
    inputText='Summarize confidentiality obligations and compute 3+4.',
)
chunks = []
for event in stream_resp.get('completion', []):
    chunk = event.get('chunk', {})
    if 'bytes' in chunk:
        chunks.append(chunk['bytes'].decode('utf-8', errors='replace'))
stream_text = ''.join(chunks)
assert stream_text, 'No stream text from InvokeAgent'
print(json.dumps({'invoke_agent_boto3': 'ok', 'stream_preview': stream_text[:120]}))
PY"

  echo
  echo "== Runtime malformed-input contract =="
  run_remote "POD=\$(kubectl -n ${NAMESPACE} get pod -l app.kubernetes.io/instance=quote-planning-agent -o jsonpath='{.items[0].metadata.name}'); \
kubectl -n ${NAMESPACE} exec -i \"\$POD\" -c sam -- python - <<'PY'
import json
import urllib.request
import urllib.error

url = '${RUNTIME_URL}/invoke-agent'
bad_payload = {'agentId': 'x', 'agentAliasId': 'y', 'sessionId': 'bad-input'}
req = urllib.request.Request(
    url,
    data=json.dumps(bad_payload).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
    method='POST',
)

try:
    urllib.request.urlopen(req, timeout=10)
    raise SystemExit('Expected 4xx, got success')
except urllib.error.HTTPError as err:
    body = err.read().decode('utf-8')
    parsed = json.loads(body)
    assert err.code in (400, 422), err.code
    assert 'error' in parsed, parsed
    print(json.dumps({'malformed_request_status': err.code, 'error_key': parsed.get('error')}))
PY"

  echo
  echo "== Verify sam_bedrock_agent invoke_bedrock_agent in bedrock-legal-agent =="
  run_remote "AGENT_POD=\$(kubectl -n ${NAMESPACE} get pod -l app.kubernetes.io/instance=${AGENT_RELEASE} -o jsonpath='{.items[0].metadata.name}'); \
kubectl -n ${NAMESPACE} exec -i \"\$AGENT_POD\" -c sam -- python - <<'PY'
import asyncio
import json
from sam_bedrock_agent.bedrock_agent import invoke_bedrock_agent

class _S:
    id = 'legaldemo01'

class _I:
    session = _S()

class _C:
    _invocation_context = _I()

config = {
    'bedrock_agent_id': 'bdrklgl01',
    'bedrock_agent_alias_id': 'ldnlocal1',
    'allow_files': False,
    'amazon_bedrock_runtime_config': {
        'endpoint_url': '${RUNTIME_URL}',
        'boto3_config': {
            'region_name': 'us-east-1',
            'aws_access_key_id': 'demoAccessKey',
            'aws_secret_access_key': 'demoSecretKey',
        },
    },
}

result = asyncio.run(
    invoke_bedrock_agent(
        input_text='List two legal checks for a new supplier and compute 5+7.',
        tool_context=_C(),
        tool_config=config,
    )
)
print(json.dumps(result))
if result.get('status') != 'success':
    raise SystemExit(1)
PY"

  echo
  echo "== Agent logs (tail 80) =="
  run_remote "kubectl -n ${NAMESPACE} logs deployment/${AGENT_RELEASE} -c sam --tail=80"
} | tee "$VERIFY_FILE"

log "Verification report written to $VERIFY_FILE"
