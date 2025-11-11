#!/bin/bash
set -e

# Load versions
source "$(dirname "$0")/../versions.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing EnvoyGateway ${ENVOY_GATEWAY_VERSION} in Namespace Mode${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# Install/Upgrade EnvoyGateway using Helm (OCI registry) with Backend API enabled and Namespace Mode
echo -e "${BLUE}🔧 Installing/Upgrading EnvoyGateway (${ENVOY_GATEWAY_VERSION}) in Namespace Mode using Helm...${NC}"
echo -e "${YELLOW}ℹ️  Namespace Mode: EnvoyGateway will watch 'default' and 'envoy-gateway-system' namespaces only${NC}"
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
    --version ${ENVOY_GATEWAY_HELM_CHART_VERSION} \
    --namespace envoy-gateway-system \
    --create-namespace \
    --values deployments/helm/values-namespace-mode.yaml \
    --wait

# Wait for EnvoyGateway to be ready
echo -e "${BLUE}⏳ Waiting for EnvoyGateway to be ready...${NC}"
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

# Create default EnvoyGateway GatewayClass
echo -e "${BLUE}🌐 Creating default EnvoyGateway GatewayClass...${NC}"
cat <<EOF | kubectl apply -f -
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF

echo -e "${GREEN}✅ Default GatewayClass 'eg' created${NC}"

# Install/Upgrade cert-manager
echo -e "${BLUE}🔐 Installing/Upgrading cert-manager (${CERT_MANAGER_VERSION})...${NC}"
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version ${CERT_MANAGER_VERSION} \
    --set installCRDs=true \
    --set "extraArgs={--enable-gateway-api}" \
    --wait

# Wait for cert-manager to be ready
echo -e "${BLUE}⏳ Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=300s

# Install cert-manager issuers
echo -e "${BLUE}📋 Installing cert-manager issuers...${NC}"
kubectl apply -f configs/cert-manager-issuers.yaml

# Wait for CA certificate to be ready
echo -e "${BLUE}⏳ Waiting for CA certificate to be ready...${NC}"
kubectl wait --for=condition=Ready certificate/selfsigned-ca -n cert-manager --timeout=300s

echo -e "${GREEN}✅ EnvoyGateway ${ENVOY_GATEWAY_VERSION} installation complete in Namespace Mode!${NC}"
echo -e "${YELLOW}ℹ️  Watched namespaces: default, envoy-gateway-system${NC}"

# Show status
echo -e "${BLUE}📦 EnvoyGateway pods:${NC}"
kubectl get pods -n envoy-gateway-system

echo ""
echo -e "${BLUE}🎯 Available GatewayClasses:${NC}"
kubectl get gatewayclass -o wide
