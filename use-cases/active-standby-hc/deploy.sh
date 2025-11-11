#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying Active-Standby Health Check Use Case${NC}"
echo "=================================================="

# Check if EnvoyGateway is installed
if ! kubectl get namespace envoy-gateway-system &> /dev/null; then
    echo -e "${RED}❌ EnvoyGateway is not installed. Please install EnvoyGateway first.${NC}"
    echo ""
    echo "💡 Install EnvoyGateway using:"
    echo "   task setup-all"
    exit 1
fi

# Check if Backend API is enabled
if ! kubectl get crd backends.gateway.envoyproxy.io &> /dev/null; then
    echo -e "${RED}❌ Backend API is not enabled. Please run setup first.${NC}"
    echo ""
    echo "💡 Enable Backend API using:"
    echo "   task setup-all"
    exit 1
fi

# Check if default GatewayClass exists
if ! kubectl get gatewayclass eg &> /dev/null; then
    echo -e "${YELLOW}⚠️  Default 'eg' GatewayClass not found. Creating it...${NC}"
    cat <<EOF | kubectl apply -f -
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF
    echo -e "${GREEN}✅ GatewayClass 'eg' created${NC}"
else
    echo -e "${GREEN}✅ Using existing 'eg' GatewayClass${NC}"
fi

# Deploy namespace
echo -e "${BLUE}📦 Creating namespace...${NC}"
kubectl apply -f namespace.yaml

# Deploy Backend resources
echo -e "${BLUE}🔗 Creating Backend resources...${NC}"
kubectl apply -f backend.yaml

# Deploy Gateway and HTTPRoute
echo -e "${BLUE}🌐 Creating Gateway and HTTPRoute...${NC}"
kubectl apply -f gateway.yaml

# Deploy BackendTrafficPolicy
echo -e "${BLUE}🔒 Creating BackendTrafficPolicy with health checks...${NC}"
kubectl apply -f backend-traffic-policy.yaml

# Wait for gateway to be ready
echo -e "${BLUE}⏳ Waiting for gateway to be ready...${NC}"
sleep 10

echo -e "${GREEN}✅ Active-Standby Health Check use case deployed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Status:${NC}"
echo "  Namespace:"
kubectl get namespace active-standby-hc -o wide
echo ""
echo "  Backend Resources:"
kubectl get backend -n active-standby-hc
echo ""
echo "  Gateway:"
kubectl get gateway,httproute -n active-standby-hc
echo ""
echo "  BackendTrafficPolicy:"
kubectl get backendtrafficpolicy -n active-standby-hc
echo ""

echo -e "${BLUE}🧪 Quick Test:${NC}"
echo "============="
echo ""
echo "Test the active-standby health check behavior:"
echo ""
echo "  curl --resolve active-standby.demo.int:18080:127.0.0.1 http://active-standby.demo.int:18080/get"
echo ""
echo "💡 This uses --resolve to test against localhost (kind cluster) without port-forwarding"
echo ""