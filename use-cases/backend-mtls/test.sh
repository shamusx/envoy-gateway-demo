#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Backend mTLS Use Case${NC}"
echo "================================"

# Check if the use case is deployed
if ! kubectl get namespace httpbin-tls &>/dev/null; then
    echo -e "${RED}❌ httpbin-tls namespace not found. Please deploy the use case first.${NC}"
    echo "Run: task deploy-backend-mtls"
    exit 1
fi

echo "🔍 Checking deployment status..."

# Check pods
echo "📊 Pod Status:"
kubectl get pods -n httpbin-tls

# Check certificates
echo -e "\n🔐 Certificate Status:"
kubectl get certificate -n httpbin-tls

# Check gateway
echo -e "\n🚪 Gateway Status:"
kubectl get gateway -n httpbin-tls

# Check HTTPRoute
echo -e "\n🛣️  HTTPRoute Status:"
kubectl get httproute -n httpbin-tls

# Check BackendTLSPolicy
echo -e "\n🔒 BackendTLSPolicy Status:"
kubectl get backendtlspolicy -n httpbin-tls

# Test connectivity
echo -e "\n🧪 Testing Connectivity..."

# Get the gateway service
GATEWAY_SERVICE=$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-namespace=httpbin-tls -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -n "$GATEWAY_SERVICE" ]]; then
    echo "🔗 Found gateway service: $GATEWAY_SERVICE"
    
    # Port forward and test
    echo "🚀 Starting port-forward to test mTLS endpoint..."
    kubectl port-forward -n envoy-gateway-system svc/$GATEWAY_SERVICE 18080:18080 &>/dev/null &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to be ready
    sleep 3
    
    # Test mTLS endpoint
    echo "🧪 Testing mTLS backend endpoint..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: mtls-backend.demo.int" "http://localhost:18080/get" 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ mTLS backend endpoint test passed (HTTP $RESPONSE)${NC}"
    else
        echo -e "${RED}❌ mTLS backend endpoint test failed (HTTP $RESPONSE)${NC}"
    fi
    
    # Clean up port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
else
    echo -e "${YELLOW}⚠️  Gateway service not found - skipping connectivity tests${NC}"
fi

echo -e "\n${GREEN}✅ Backend mTLS use case testing completed${NC}"
echo ""
echo "💡 Manual testing commands:"
echo "  kubectl port-forward -n envoy-gateway-system svc/\$GATEWAY_SERVICE 18080:18080"
echo "  curl -H 'Host: mtls-backend.demo.int' http://localhost:18080/get"