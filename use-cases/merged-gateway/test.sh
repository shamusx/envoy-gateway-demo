#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Merged Gateway Mode Use Case${NC}"
echo "========================================"

# Check if the use case is deployed
if ! kubectl get namespace team-a &>/dev/null || ! kubectl get namespace team-b &>/dev/null; then
    echo -e "${RED}❌ team-a or team-b namespace not found. Please deploy the use case first.${NC}"
    echo "Run: task deploy-merged-gateway"
    exit 1
fi

echo "🔍 Checking deployment status..."

# Check pods
echo "📊 Pod Status:"
kubectl get pods -n team-a
kubectl get pods -n team-b
kubectl get pods -n httpbin

# Check gateways
echo -e "\n🚪 Gateway Status:"
kubectl get gateway -n team-a
kubectl get gateway -n team-b

# Check HTTPRoutes
echo -e "\n🛣️  HTTPRoute Status:"
kubectl get httproute -n team-a
kubectl get httproute -n team-b

# Test connectivity
echo -e "\n🧪 Testing Connectivity..."

# Get the gateway service
GATEWAY_SERVICE=$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-namespace=team-a -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -n "$GATEWAY_SERVICE" ]]; then
    echo "🔗 Found gateway service: $GATEWAY_SERVICE"
    
    # Port forward and test
    echo "🚀 Starting port-forward to test endpoints..."
    kubectl port-forward -n envoy-gateway-system svc/$GATEWAY_SERVICE 18080:18080 &>/dev/null &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to be ready
    sleep 3
    
    # Test team-a web endpoint
    echo "🧪 Testing team-a web endpoint..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: web-team-a.merged-gw.int" "http://localhost:18080/get" 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ Team-A web endpoint test passed (HTTP $RESPONSE)${NC}"
    else
        echo -e "${RED}❌ Team-A web endpoint test failed (HTTP $RESPONSE)${NC}"
    fi
    
    # Test team-a API endpoint
    echo "🧪 Testing team-a API endpoint..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: api-team-a.merged-gw.int" "http://localhost:18080/api/get" 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ Team-A API endpoint test passed (HTTP $RESPONSE)${NC}"
    else
        echo -e "${RED}❌ Team-A API endpoint test failed (HTTP $RESPONSE)${NC}"
    fi
    
    # Test team-b web endpoint
    echo "🧪 Testing team-b web endpoint..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: web-team-b.merged-gw.int" "http://localhost:18080/get" 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ Team-B web endpoint test passed (HTTP $RESPONSE)${NC}"
    else
        echo -e "${RED}❌ Team-B web endpoint test failed (HTTP $RESPONSE)${NC}"
    fi
    
    # Test team-b API endpoint
    echo "🧪 Testing team-b API endpoint..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: api-team-b.merged-gw.int" "http://localhost:18080/api/get" 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ Team-B API endpoint test passed (HTTP $RESPONSE)${NC}"
    else
        echo -e "${RED}❌ Team-B API endpoint test failed (HTTP $RESPONSE)${NC}"
    fi
    
    # Clean up port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
else
    echo -e "${YELLOW}⚠️  Gateway service not found - skipping connectivity tests${NC}"
fi

echo -e "\n${GREEN}✅ Merged Gateway Mode use case testing completed${NC}"
echo ""
echo "💡 Manual testing commands:"
echo "  kubectl port-forward -n envoy-gateway-system svc/\$GATEWAY_SERVICE 18080:18080"
echo "  curl -H 'Host: web-team-a.merged-gw.int' http://localhost:18080/get"
echo "  curl -H 'Host: api-team-a.merged-gw.int' http://localhost:18080/api/get"
echo "  curl -H 'Host: web-team-b.merged-gw.int' http://localhost:18080/get"
echo "  curl -H 'Host: api-team-b.merged-gw.int' http://localhost:18080/api/get"