#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying HTTP-to-HTTPS Redirect with Wildcard SSL Use Case${NC}"
echo "================================================================"

# Check if EnvoyGateway is installed
if ! kubectl get namespace envoy-gateway-system &> /dev/null; then
    echo -e "${RED}❌ EnvoyGateway is not installed. Please install EnvoyGateway first.${NC}"
    echo ""
    echo "💡 Install EnvoyGateway using:"
    echo "   task setup-all"
    exit 1
fi

# Deploy httpbin if not already deployed
if ! kubectl get namespace httpbin &> /dev/null; then
    echo -e "${BLUE}📦 Deploying httpbin...${NC}"
    kubectl apply -f ../../examples/httpbin/deployment.yaml -n httpbin
    kubectl wait --for=condition=Available deployment/httpbin -n httpbin --timeout=120s
    echo -e "${GREEN}✅ httpbin deployed${NC}"
else
    echo -e "${GREEN}✅ httpbin already deployed${NC}"
fi

# Deploy GatewayClass and EnvoyProxy configuration
echo "🏗️  Creating GatewayClass with merged gateway support..."
kubectl apply -f gatewayclass.yaml

# Create wildcard TLS certificate
echo -e "${BLUE}🔐 Creating wildcard TLS certificate...${NC}"
kubectl apply -f cert-wildcard.yaml

echo -e "${BLUE}⏳ Waiting for certificate to be ready...${NC}"
kubectl wait --for=condition=Ready certificate/httpbin-wc -n httpbin --timeout=120s
echo -e "${GREEN}✅ Wildcard certificate created${NC}"

# Deploy Gateway
echo -e "${BLUE}🌐 Creating Gateway with wildcard listeners...${NC}"
kubectl apply -f gateway.yaml

# Deploy HTTP-to-HTTPS redirect route
echo -e "${BLUE}🔄 Creating HTTP-to-HTTPS redirect route...${NC}"
kubectl apply -f redirect-httproute.yaml

# Deploy HTTPS backend route
echo -e "${BLUE}🛣️  Creating HTTPS backend route...${NC}"
kubectl apply -f redirect-web-httpbin.yaml

# Wait for gateway to be ready
echo -e "${BLUE}⏳ Waiting for gateway to be ready...${NC}"
sleep 10

echo -e "${GREEN}✅ HTTP-to-HTTPS Redirect with Wildcard SSL use case deployed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Status:${NC}"
echo "  Certificate:"
kubectl get certificate -n httpbin httpbin-wc
echo ""
echo "  Gateway:"
kubectl get gateway -n httpbin httpbin-wildcard
echo ""
echo "  HTTPRoutes:"
kubectl get httproute -n httpbin
echo ""

echo -e "${BLUE}🧪 Quick Test:${NC}"
echo "============="
echo ""
echo "Test HTTP-to-HTTPS redirect (should return 302):"
echo "  curl --resolve web.httpbin.io:8080:127.0.0.1 http://web.httpbin.io:8080/get -I"
echo ""
echo "Test HTTPS endpoint:"
echo "  curl --resolve web.httpbin.io:8443:127.0.0.1 https://web.httpbin.io:8443/get -k"
echo ""
echo "💡 HTTP requests are automatically redirected to HTTPS"
echo "💡 Wildcard cert covers *.httpbin.io and *.httpbin-internal.io"
echo ""
