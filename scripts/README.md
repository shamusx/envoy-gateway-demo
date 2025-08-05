# EnvoyGateway Use Case Evaluation Script

This directory contains a script to automatically detect and evaluate deployed EnvoyGateway use cases.

## Script Overview

### `evaluate-usecases.sh` - Smart Use Case Evaluation
An intelligent script that automatically detects which use cases are deployed and evaluates only those.

**Features:**
- 🔍 **Auto-detection**: Automatically discovers deployed use cases
- ✅ **Resource validation**: Checks existence and readiness of components
- 🧪 **Connectivity testing**: Tests HTTP endpoints via port-forwarding
- 📊 **Detailed reporting**: Color-coded status with comprehensive feedback
- 🎯 **Targeted evaluation**: Only evaluates what's actually deployed

**Usage:**
```bash
# Auto-detect and evaluate all deployed use cases
./scripts/evaluate-usecases.sh

# Evaluate specific use case (if deployed)
./scripts/evaluate-usecases.sh merged-gateway
./scripts/evaluate-usecases.sh backend-mtls

# Check EnvoyGateway installation only
./scripts/evaluate-usecases.sh envoygateway

# Show help
./scripts/evaluate-usecases.sh help
```

## Use Cases Tested

### Merged Gateway Use Case
**Hostnames tested:**
- `web-team-a.merged-gw.int:18080` - Team A web traffic
- `api-team-a.merged-gw.int:18080/api` - Team A API traffic  
- `web-team-b.merged-gw.int:18080` - Team B web traffic
- `api-team-b.merged-gw.int:18080/api` - Team B API traffic

**Components checked:**
- Namespaces: `team-a`, `team-b`
- Gateways: `team-a-gateway`, `team-b-gateway`
- HTTPRoutes: `team-a-web`, `team-a-api`, `team-b-web`, `team-b-api`
- Backend: `httpbin` deployment

### Backend mTLS Use Case
**Hostnames tested:**
- `mtls-backend.demo.int:18443` - mTLS backend endpoints

**Components checked:**
- Namespace: `httpbin-tls`
- Certificates: `httpbin-tls-cert`, `envoygateway-client-cert`
- Gateway: `backend-mtls-gateway`
- HTTPRoute: `backend-mtls-route`
- BackendTLSPolicy: `backend-mtls-policy`
- Backend: `httpbin-tls` deployment

## Prerequisites

Before running the evaluation scripts, ensure:

1. **kubectl** is installed and configured
2. **EnvoyGateway** is installed in the cluster
3. **Use cases are deployed** (run their respective deploy.sh scripts)

## Example Output

```bash
$ ./scripts/evaluate-usecases.sh

🚀 EnvoyGateway Use Cases Evaluation
====================================
Tue Jul 29 10:30:00 PDT 2025

ℹ️  INFO: Detecting deployed use cases...
✅ PASS: Merged Gateway use case detected
✅ PASS: Backend mTLS use case detected

Found 2 deployed use case(s): merged-gateway backend-mtls

🔍 Checking EnvoyGateway Installation
========================================
✅ PASS: namespace/envoy-gateway-system exists
✅ PASS: deployment/envoy-gateway in namespace envoy-gateway-system is ready
✅ PASS: GatewayClass merged-gateway exists

EnvoyGateway Summary: 3/3 checks passed

🔍 Evaluating Merged Gateway Use Case
================================================
✅ PASS: namespace/team-a exists
✅ PASS: namespace/team-b exists
✅ PASS: gateway/team-a-gateway in namespace team-a exists
✅ PASS: gateway/team-b-gateway in namespace team-b exists
ℹ️  INFO: Testing endpoint: web-team-a.merged-gw.int:18080/get
✅ PASS: Endpoint web-team-a.merged-gw.int/get returned status 200

Merged Gateway Summary: 12/12 checks passed

🔍 Evaluating Backend mTLS Use Case
=============================================
✅ PASS: namespace/httpbin-tls exists
✅ PASS: certificate/httpbin-tls-cert in namespace httpbin-tls is ready
✅ PASS: certificate/envoygateway-client-cert in namespace httpbin-tls is ready
ℹ️  INFO: Testing endpoint: mtls-backend.demo.int:18443/get
✅ PASS: Endpoint mtls-backend.demo.int/get returned status 200

Backend mTLS Summary: 8/8 checks passed

📊 Overall Evaluation Summary
==============================
✅ PASS: All deployed use cases are working correctly!
```

### When No Use Cases Are Deployed

```bash
$ ./scripts/evaluate-usecases.sh

🚀 EnvoyGateway Use Cases Evaluation
====================================
Tue Jul 29 10:30:00 PDT 2025

ℹ️  INFO: Detecting deployed use cases...
ℹ️  INFO: Merged Gateway use case not deployed
ℹ️  INFO: Backend mTLS use case not deployed
⚠️  WARN: No use cases detected as deployed

💡 Deploy use cases with:
  cd use-cases/merged-gateway && ./deploy.sh
  cd use-cases/backend-mtls && ./deploy.sh
```

## Troubleshooting

If tests fail, check:

1. **Pod status**: `kubectl get pods -A`
2. **Gateway status**: `kubectl get gateway -A`
3. **Certificate status**: `kubectl get certificate -A`
4. **EnvoyGateway logs**: `kubectl logs -n envoy-gateway-system deployment/envoy-gateway`

## Integration with CI/CD

The script returns appropriate exit codes:
- `0` - All deployed use cases are working correctly
- `>0` - Number of failed checks across all deployed use cases

Example CI usage:
```bash
# Deploy use cases
cd use-cases/merged-gateway && ./deploy.sh
cd ../backend-mtls && ./deploy.sh

# Wait for deployment
sleep 30

# Run evaluation (auto-detects what's deployed)
./scripts/evaluate-usecases.sh
```

## Smart Detection Logic

The script automatically detects deployed use cases by checking for key resources:

- **Merged Gateway**: Looks for `team-a` and `team-b` namespaces
- **Backend mTLS**: Looks for `httpbin-tls` namespace and `backend-mtls-gateway`

This means you can run the script anytime and it will only evaluate what's actually deployed, making it perfect for different deployment scenarios.