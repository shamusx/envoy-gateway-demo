# EnvoyGateway Sandbox

A comprehensive testing environment for EnvoyGateway with Kind clusters, existing Kubernetes deployments, and practical use case demonstrations.

## Quick Start

```bash
# Clone and setup
git clone <repo-url>
cd eg-sandbox

# Complete setup with all use cases (recommended)
task setup-all          # Setup Kind cluster + EnvoyGateway + all use cases

# Or step-by-step setup
task setup              # Interactive setup - choose Kind or existing K8s
task deploy-all         # Deploy all use cases
task test-all           # Test all deployments
```

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - For local clusters
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Helm](https://helm.sh/docs/intro/install/) - Package manager for Kubernetes
- [Task](https://taskfile.dev/installation/) - Modern task runner

## Deployment Modes

- **Kind Cluster**: Local Kubernetes cluster for development and testing
- **Kubernetes**: Deploy to existing cluster (local or remote)

## Features

- **🚀 Complete EnvoyGateway Environment**: Automated setup with Kind or existing clusters
- **🔧 Helm-based Installation**: Proper configuration management with `helm upgrade --install`
- **🔌 Backend API Extension**: Enabled by default for advanced backend configurations
- **📚 Practical Use Cases**: Real-world scenarios with comprehensive documentation
- **🧪 Automated Testing**: Deploy and test use cases with single commands
- **🔄 Idempotent Operations**: Re-run setup safely without breaking existing deployments
- **🧹 Easy Cleanup**: Clean infrastructure or individual use cases

## Commands

### Available Commands

```bash
# Main setup and management
task                    # Show all available tasks
task setup-all          # Complete setup - create cluster and install all components
task status             # Check EnvoyGateway status
task versions           # Show component versions
task verify-installation # Show current status of all components
task clean-task-cache   # Clean Task cache for infrastructure tasks

# Use case deployment and testing
task deploy-all         # Deploy all use cases
task test-all           # Test all use cases

# Infrastructure management
task create-cluster     # Create kind cluster
task install-envoy-gateway # Install EnvoyGateway using Helm
task kubectx            # Switch to the kind cluster context

# Cleanup
task clean-all          # Clean up all environments and use cases
task clean-kind         # Clean up Kind cluster
task clean-usecases     # Clean up all use cases
```

### Use Cases

```bash
# Deploy all use cases at once
task deploy-all         # Deploy all use cases
task test-all           # Test all use cases

# Deploy individual use cases
task deploy-basic-routing       # Basic Gateway and HTTPRoute with multiple paths
task deploy-merged-gateway      # Multi-tenant gateway sharing
task deploy-backend-mtls        # Backend mTLS authentication
task deploy-active-standby-hc   # Health check with failover

# Test individual use cases
task test-basic-routing
task test-merged-gateway
task test-backend-mtls
task test-active-standby-hc
```

## Use Case Highlights

### 🚦 Basic Routing
**Fundamental Gateway API concepts with path-based routing**
- Single Gateway with HTTP listener
- Multiple HTTPRoutes demonstrating different path patterns
- Simple same-namespace routing configuration
- Perfect starting point for learning Gateway API

### 🔀 Merged Gateway Mode
**Multi-tenant gateway sharing with resource efficiency**
- Multiple Gateway objects share single EnvoyProxy instance
- Team-based namespace isolation
- Cross-namespace routing with ReferenceGrants

### 🔐 Backend mTLS
**Secure backend communication with certificate management**
- EnvoyGateway presents client certificates to backends
- Automated certificate provisioning via cert-manager
- Policy-based TLS configuration

### ⚖️ Active-Standby Health Check
**High availability with automatic failover**
- Continuous health monitoring of external backends
- Automatic traffic switching on backend failures
- Backend API with external endpoint configuration

## Configuration

### Helm Values
EnvoyGateway is configured via `deployments/helm/values.yaml`:
```yaml
config:
  envoyGateway:
    extensionApis:
      enableBackend: true  # Backend API enabled by default
    logging:
      level:
        default: info
```

### Installation Behavior
- **Idempotent**: `task setup-all` always runs `helm upgrade --install`
- **No manual ConfigMaps**: All configuration via Helm values
- **Infrastructure caching**: Only cluster/deps use status checks

## Troubleshooting

### Common Issues

1. **Re-run setup** (always safe):
   ```bash
   task setup-all
   ```

2. **Check installation status**:
   ```bash
   kubectl get pods -n envoy-gateway-system
   kubectl get gatewayclass
   ```

3. **Verify Backend API**:
   ```bash
   kubectl get crd backends.gateway.envoyproxy.io
   ```

4. **Check Helm configuration**:
   ```bash
   helm get values eg -n envoy-gateway-system
   ```

### Clean and Rebuild

```bash
task clean-task-cache  # Clean infrastructure cache
task setup-all         # Rebuild from scratch
```

## Component Versions

All component versions are centralized in [`versions.env`](./versions.env) for easy management.

## Project Structure

```
eg-sandbox/
├── deployments/
│   └── helm/
│       ├── values.yaml              # EnvoyGateway Helm configuration (cluster-wide)
│       └── values-namespace-mode.yaml # EnvoyGateway Helm configuration (namespace-scoped)
├── use-cases/              # Practical demonstrations
│   ├── basic-routing/      # Basic Gateway and HTTPRoute patterns
│   ├── merged-gateway/     # Multi-tenant gateway sharing
│   ├── backend-mtls/       # Backend mTLS authentication
│   ├── active-standby-hc/  # Health check with failover
│   └── README.md           # Use cases overview
├── examples/               # Sample applications (httpbin, etc.)
├── scripts/                # Automation and setup scripts
├── configs/                # Configuration files (cert-manager, etc.)
├── Taskfile.yml            # Task definitions
└── versions.env            # Centralized version management
```

## Contributing

When adding new use cases:
1. Create descriptive directory names (no numbers)
2. Include comprehensive README with mermaid diagrams
3. Provide deploy.sh and test.sh scripts
4. Update main README and use-cases README
5. Add Task definitions to Taskfile.yml