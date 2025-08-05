# EnvoyGateway Use Cases

This directory contains practical use cases demonstrating various EnvoyGateway features and deployment patterns.

## Available Use Cases

### Merged Gateway Mode
**Directory**: `merged-gateway/`
**Description**: Demonstrates how to configure EnvoyGateway in merged gateway mode, allowing multiple Gateway objects to share a single EnvoyProxy deployment.

**Key Features**:
- Multiple Gateway objects managed by single proxy
- Resource efficiency through shared infrastructure
- Multi-tenancy support
- Team-based namespace isolation

**Deploy**: `./deploy.sh` or `task deploy-merged-gateway`
**Test**: `./test.sh` or `task test-merged-gateway`

### Backend mTLS
**Directory**: `backend-mtls/`
**Description**: Demonstrates EnvoyGateway establishing mTLS connections to backend services using BackendTLSPolicy.

**Key Features**:
- Backend mTLS authentication
- Certificate management via cert-manager
- TLS validation and encryption
- Policy-based configuration

**Deploy**: `./deploy.sh` or `task deploy-backend-mtls`
**Test**: `./test.sh` or `task test-backend-mtls`

### Active-Standby Health Check
**Directory**: `active-standby-hc/`
**Description**: Demonstrates active health checking with Backend resources in an active-standby configuration.

**Key Features**:
- Active health checking of external backends
- Automatic failover between primary and standby
- Backend API with external endpoints
- Configurable health check thresholds

**Deploy**: `./deploy.sh`
**Test**: `./test.sh`

## General Usage

Each use case follows a consistent structure:

```
use-cases/use-case-name/
├── README.md           # Detailed documentation
├── deploy.sh          # Deployment script
├── test.sh            # Testing script
├── *.yaml             # Kubernetes manifests
└── cleanup.sh         # Optional cleanup script
```

## Prerequisites

Before running any use case:

1. Have a Kubernetes cluster ready (Kind or existing)
2. Install EnvoyGateway: `make kind-setup` or `make k8s-setup`
3. Deploy httpbin application: `kubectl apply -f examples/httpbin/deployment.yaml`

## Testing

Each use case includes:
- Automated deployment scripts
- Comprehensive testing scripts
- Port-forwarding for local testing
- Cleanup procedures

## Contributing

When adding new use cases:
1. Use descriptive directory names (no numbers)
2. Include comprehensive README
3. Provide deploy and test scripts
4. Update this main README
5. Add Makefile targets