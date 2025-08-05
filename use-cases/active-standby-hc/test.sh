#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Active-Standby Health Check Use Case${NC}"
echo "=============================================="

# Check if the use case is deployed
if ! kubectl get namespace active-standby-hc &>/dev/null; then
    echo -e "${RED}❌ active-standby-hc namespace not found. Please deploy the use case first.${NC}"
    echo "Run: ./deploy.sh"
    exit 1
fi

echo -e "${BLUE}🔍 Checking deployment status...${NC}"

# Check Backend resources
echo -e "${BLUE}📊 Backend Resources:${NC}"
kubectl get backend -n active-standby-hc

# Check gateway
echo -e "\n${BLUE}🚪 Gateway Status:${NC}"
kubectl get gateway -n active-standby-hc

# Check HTTPRoute
echo -e "\n${BLUE}🛣️  HTTPRoute Status:${NC}"
kubectl get httproute -n active-standby-hc

# Check BackendTrafficPolicy
echo -e "\n${BLUE}🔒 BackendTrafficPolicy Status:${NC}"
kubectl get backendtrafficpolicy -n active-standby-hc

# Test connectivity
echo -e "\n${BLUE}🧪 Testing Connectivity...${NC}"

# Get the gateway service
GATEWAY_SERVICE=$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-namespace=active-standby-hc -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -n "$GATEWAY_SERVICE" ]]; then
    echo -e "${GREEN}🔗 Found gateway service: $GATEWAY_SERVICE${NC}"
    
    # Port forward and test
    echo -e "${BLUE}🚀 Starting port-forward to test endpoints...${NC}"
    kubectl port-forward -n envoy-gateway-system svc/$GATEWAY_SERVICE 18080:18080 &>/dev/null &
    PORT_FORWARD_PID=$!
    
    # Wait for port-forward to be ready
    sleep 3
    
    # Test primary endpoint
    echo -e "${BLUE}🧪 Testing active-standby endpoint...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: active-standby.demo.int" "http://localhost:18080/get" 2>/dev/null || echo "000")
    
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ Active-Standby endpoint test passed (HTTP $RESPONSE)${NC}"
        
        # Get response body to show which backend responded
        echo -e "${BLUE}📋 Response details:${NC}"
        RESPONSE_BODY=$(curl -s -H "Host: active-standby.demo.int" "http://localhost:18080/get" 2>/dev/null || echo "Failed to get response")
        echo "$RESPONSE_BODY" | head -10
    else
        echo -e "${RED}❌ Active-Standby endpoint test failed (HTTP $RESPONSE)${NC}"
    fi
    
    # Test multiple requests to see load balancing behavior
    echo -e "\n${BLUE}🔄 Testing multiple requests to observe backend selection:${NC}"
    for i in {1..5}; do
        RESPONSE=$(curl -s -H "Host: active-standby.demo.int" "http://localhost:18080/get" 2>/dev/null | grep -o '"Host": "[^"]*"' || echo "Request $i failed")
        echo "Request $i: $RESPONSE"
        sleep 1
    done
    
    # Clean up port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
else
    echo -e "${YELLOW}⚠️  Gateway service not found - skipping connectivity tests${NC}"
fi

# Check health check status
echo -e "\n${BLUE}🏥 Health Check Status:${NC}"
kubectl describe backendtrafficpolicy active-standby-health-policy -n active-standby-hc | grep -A 10 "Health Check" || echo "Health check details not available"

# Show EnvoyGateway logs related to health checks
echo -e "\n${BLUE}📋 Recent EnvoyGateway logs (health check related):${NC}"
kubectl logs -n envoy-gateway-system -l app.kubernetes.io/name=envoy-gateway --tail=20 | grep -i health || echo "No health check logs found"

echo -e "\n${GREEN}✅ Active-Standby Health Check use case testing completed${NC}"
echo ""
echo -e "${BLUE}💡 Manual testing commands:${NC}"
echo "  kubectl port-forward -n envoy-gateway-system svc/\$GATEWAY_SERVICE 18080:18080"
echo "  curl -H 'Host: active-standby.demo.int' http://localhost:18080/get"
echo "  kubectl get backend -n active-standby-hc -o yaml"
echo "  kubectl describe backendtrafficpolicy active-standby-health-policy -n active-standby-hc"