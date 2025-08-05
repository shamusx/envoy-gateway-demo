#!/bin/bash
set -e

CLUSTER_NAME=${1:-envoygateway-sandbox}

# Load versions
source "$(dirname "$0")/../versions.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Creating Kind cluster: ${CLUSTER_NAME}${NC}"

# Check if Kind cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${GREEN}✅ Kind cluster '${CLUSTER_NAME}' already exists${NC}"
    # Set kubectl context to the existing cluster
    kubectl cluster-info --context kind-${CLUSTER_NAME}
    exit 0
fi

# Create kind cluster configuration
cat <<EOF > /tmp/kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 18080
    hostPort: 18080
    protocol: TCP
  - containerPort: 18443
    hostPort: 18443
    protocol: TCP
EOF

# Create kind cluster
echo -e "${BLUE}📦 Creating Kind cluster with Kubernetes ${KUBERNETES_VERSION}...${NC}"
kind create cluster --config /tmp/kind-config.yaml --image kindest/node:${KUBERNETES_VERSION}

# Clean up config file
rm -f /tmp/kind-config.yaml

# Wait for cluster to be ready
echo -e "${BLUE}⏳ Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo -e "${GREEN}✅ Kind cluster '${CLUSTER_NAME}' created successfully!${NC}"
echo -e "${BLUE}🔍 Cluster info:${NC}"
kubectl cluster-info --context kind-${CLUSTER_NAME}