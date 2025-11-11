#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Basic Routing Use Case${NC}"
echo "=================================="

# Check if the use case is deployed
if ! kubectl get gateway -n httpbin httpbin-gateway &>/dev/null; then
    echo -e "${RED}❌ Gateway 'httpbin-gateway' not found in httpbin namespace. Please deploy the use case first.${NC}"
    echo "Run: task deploy-basic-routing"
    exit 1
fi

echo "🔍 Checking deployment status..."

# Check gateway
echo "📊 Gateway Status:"
kubectl get gateway -n httpbin httpbin-gateway

# Check HTTPRoutes
echo -e "\n🛣️  HTTPRoute Status:"
kubectl get httproute -n httpbin

# Check httpbin pods
echo -e "\n📦 httpbin Pod Status:"
kubectl get pods -n httpbin

# Test connectivity
echo -e "\n🧪 Testing Connectivity..."

# Get the gateway service
GATEWAY_SERVICE=$(kubectl get service -n httpbin -l gateway.envoyproxy.io/owning-gateway-name=httpbin-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -z "$GATEWAY_SERVICE" ]]; then
    echo -e "${YELLOW}⚠️  Gateway service not found - waiting for it to be created...${NC}"
    sleep 10
    GATEWAY_SERVICE=$(kubectl get service -n httpbin -l gateway.envoyproxy.io/owning-gateway-name=httpbin-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
fi

if [[ -n "$GATEWAY_SERVICE" ]]; then
    echo -e "${BLUE}🔗 Found gateway service: $GATEWAY_SERVICE${NC}"

    # Port forward and test
    echo "🚀 Starting port-forward to test endpoints..."
    kubectl port-forward -n httpbin svc/$GATEWAY_SERVICE 8080:8080 &>/dev/null &
    PORT_FORWARD_PID=$!

    # Wait for port-forward to be ready
    sleep 3

    # Test counter
    PASSED=0
    FAILED=0

    # Test /get endpoint
    echo -e "\n${BLUE}Testing /get endpoint...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/get" 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ /get endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /get endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Test /headers endpoint
    echo -e "\n${BLUE}Testing /headers endpoint...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/headers" 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ /headers endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /headers endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Test /status/200 endpoint
    echo -e "\n${BLUE}Testing /status/200 endpoint...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/status/200" 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ /status/200 endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /status/200 endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Test /status/404 endpoint
    echo -e "\n${BLUE}Testing /status/404 endpoint...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/status/404" 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "404" ]]; then
        echo -e "${GREEN}✅ /status/404 endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /status/404 endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Test /anything endpoint with POST
    echo -e "\n${BLUE}Testing /anything endpoint (POST)...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:8080/anything" -d '{"test": "data"}' 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ /anything endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /anything endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Test /ip endpoint
    echo -e "\n${BLUE}Testing /ip endpoint...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/ip" 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ /ip endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /ip endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Test /post endpoint with POST method
    echo -e "\n${BLUE}Testing /post endpoint (POST method)...${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:8080/post" -d '{"test": "data"}' 2>/dev/null || echo "000")
    if [[ "$RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✅ /post endpoint test passed (HTTP $RESPONSE)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ /post endpoint test failed (HTTP $RESPONSE)${NC}"
        ((FAILED++))
    fi

    # Clean up port-forward
    kill $PORT_FORWARD_PID 2>/dev/null || true

    # Summary
    echo -e "\n${BLUE}=================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo -e "${BLUE}=================================${NC}"

    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed${NC}"
        exit 1
    fi

else
    echo -e "${RED}❌ Gateway service not found - cannot run connectivity tests${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Basic Routing use case testing completed${NC}"
echo ""
echo "💡 Manual testing commands:"
echo "  kubectl port-forward -n httpbin svc/\$GATEWAY_SERVICE 8080:8080"
echo "  curl http://localhost:8080/get"
echo "  curl http://localhost:8080/headers"
echo "  curl http://localhost:8080/status/200"
