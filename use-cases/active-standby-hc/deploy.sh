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

echo -e "${BLUE}🧪 Testing Instructions:${NC}"
echo "===================="
echo ""
echo "1. Get the Gateway external IP or set up port forwarding:"
echo "   # Option A: External IP (if LoadBalancer available)"
echo "   GATEWAY_IP=\$(kubectl get gateway active-standby-gateway -n active-standby-hc -o jsonpath='{.status.addresses[0].value}')"
echo "   echo \"Gateway IP: \$GATEWAY_IP\""
echo ""
echo "   # Option B: Port forwarding (recommended for local testing)"
echo "   GATEWAY_SERVICE=\$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-namespace=active-standby-hc -o jsonpath='{.items[0].metadata.name}')"
echo "   kubectl port-forward -n envoy-gateway-system service/\$GATEWAY_SERVICE 18080:18080 &"
echo "   sleep 2"
echo ""
echo "2. Test the active-standby behavior:"
echo ""
echo "   # Test primary backend (httpbingo.org)"
echo "   curl -H \"Host: active-standby.demo.int\" http://localhost:18080/get"
echo ""
echo "   # Monitor health check behavior"
echo "   kubectl logs -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-namespace=active-standby-hc --tail=20"
echo ""
echo "3. Simulate backend failure:"
echo "   # The health checks will automatically detect failures and switch to standby"
echo "   # You can monitor the behavior in the EnvoyGateway logs"
echo ""
echo "4. Verify Backend resources:"
echo "   kubectl get backend -n active-standby-hc -o yaml"
echo ""
echo "5. Check health check status:"
echo "   kubectl describe backendtrafficpolicy active-standby-health-policy -n active-standby-hc"
echo ""