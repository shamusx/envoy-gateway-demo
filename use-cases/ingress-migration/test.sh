#!/bin/bash

# Test Script for Ingress to Gateway API Migration
# This script validates that the migrated Gateway API resources are functioning correctly

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_test() {
    echo -e "${YELLOW}▶ TEST:${NC} $1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_pass() {
    echo -e "${GREEN}  ✓ PASS:${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}  ✗ FAIL:${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${CYAN}  ℹ INFO:${NC} $1"
}

# ============================================================================
# TEST SUITE
# ============================================================================

print_header "TESTING INGRESS TO GATEWAY API MIGRATION"

# ============================================================================
# Test 1: Verify Namespace Exists
# ============================================================================

print_test "Verify namespace exists"
if kubectl get namespace ingress-demo >/dev/null 2>&1; then
    print_pass "Namespace 'ingress-demo' exists"
else
    print_fail "Namespace 'ingress-demo' not found"
fi

# ============================================================================
# Test 2: Verify Backend Deployments
# ============================================================================

print_test "Verify backend deployments are ready"

if kubectl get deployment web-backend -n ingress-demo >/dev/null 2>&1; then
    REPLICAS=$(kubectl get deployment web-backend -n ingress-demo -o jsonpath='{.status.readyReplicas}')
    if [ "$REPLICAS" -ge 1 ]; then
        print_pass "web-backend deployment is ready ($REPLICAS replicas)"
    else
        print_fail "web-backend deployment has no ready replicas"
    fi
else
    print_fail "web-backend deployment not found"
fi

if kubectl get deployment api-backend -n ingress-demo >/dev/null 2>&1; then
    REPLICAS=$(kubectl get deployment api-backend -n ingress-demo -o jsonpath='{.status.readyReplicas}')
    if [ "$REPLICAS" -ge 1 ]; then
        print_pass "api-backend deployment is ready ($REPLICAS replicas)"
    else
        print_fail "api-backend deployment has no ready replicas"
    fi
else
    print_fail "api-backend deployment not found"
fi

# ============================================================================
# Test 3: Verify Services
# ============================================================================

print_test "Verify backend services exist"

if kubectl get service web-service -n ingress-demo >/dev/null 2>&1; then
    ENDPOINTS=$(kubectl get endpoints web-service -n ingress-demo -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
    print_pass "web-service exists with $ENDPOINTS endpoint(s)"
else
    print_fail "web-service not found"
fi

if kubectl get service api-service -n ingress-demo >/dev/null 2>&1; then
    ENDPOINTS=$(kubectl get endpoints api-service -n ingress-demo -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)
    print_pass "api-service exists with $ENDPOINTS endpoint(s)"
else
    print_fail "api-service not found"
fi

# ============================================================================
# Test 4: Verify Legacy Ingress Resources
# ============================================================================

print_test "Verify legacy Ingress resources exist"

INGRESS_COUNT=$(kubectl get ingress -n ingress-demo --no-headers 2>/dev/null | wc -l)
if [ "$INGRESS_COUNT" -eq 3 ]; then
    print_pass "All 3 legacy Ingress resources found"
    for ingress in web-ingress api-ingress multi-host-ingress; do
        if kubectl get ingress $ingress -n ingress-demo >/dev/null 2>&1; then
            print_pass "  - $ingress exists"
        else
            print_fail "  - $ingress not found"
        fi
    done
else
    print_fail "Expected 3 Ingress resources, found $INGRESS_COUNT"
fi

# ============================================================================
# Test 5: Verify GatewayClass
# ============================================================================

print_test "Verify GatewayClass is accepted"

if kubectl get gatewayclass envoy-ingress-migration >/dev/null 2>&1; then
    STATUS=$(kubectl get gatewayclass envoy-ingress-migration -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}')
    if [ "$STATUS" = "True" ]; then
        print_pass "GatewayClass 'envoy-ingress-migration' is accepted"
    else
        print_fail "GatewayClass 'envoy-ingress-migration' is not accepted (status: $STATUS)"
    fi
else
    print_fail "GatewayClass 'envoy-ingress-migration' not found"
fi

# ============================================================================
# Test 6: Verify Gateway
# ============================================================================

print_test "Verify Gateway is programmed"

if kubectl get gateway migration-gateway -n ingress-demo >/dev/null 2>&1; then
    PROGRAMMED=$(kubectl get gateway migration-gateway -n ingress-demo -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')
    ACCEPTED=$(kubectl get gateway migration-gateway -n ingress-demo -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}')

    if [ "$PROGRAMMED" = "True" ] && [ "$ACCEPTED" = "True" ]; then
        print_pass "Gateway 'migration-gateway' is programmed and accepted"

        # Check listeners
        LISTENER_COUNT=$(kubectl get gateway migration-gateway -n ingress-demo -o jsonpath='{.spec.listeners}' | jq '. | length')
        print_pass "Gateway has $LISTENER_COUNT listeners configured"
    else
        print_fail "Gateway 'migration-gateway' is not ready (Programmed: $PROGRAMMED, Accepted: $ACCEPTED)"
    fi
else
    print_fail "Gateway 'migration-gateway' not found"
fi

# ============================================================================
# Test 7: Verify HTTPRoutes
# ============================================================================

print_test "Verify HTTPRoutes are accepted"

ROUTES=("web-routes" "api-routes" "prod-routes" "staging-routes")
ROUTE_COUNT=0

for route in "${ROUTES[@]}"; do
    if kubectl get httproute $route -n ingress-demo >/dev/null 2>&1; then
        STATUS=$(kubectl get httproute $route -n ingress-demo -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')
        if [ "$STATUS" = "True" ]; then
            print_pass "HTTPRoute '$route' is accepted"
            ROUTE_COUNT=$((ROUTE_COUNT + 1))
        else
            print_fail "HTTPRoute '$route' is not accepted (status: $STATUS)"
        fi
    else
        print_fail "HTTPRoute '$route' not found"
    fi
done

if [ "$ROUTE_COUNT" -eq 4 ]; then
    print_pass "All 4 HTTPRoutes are properly configured"
fi

# ============================================================================
# Test 8: Verify Gateway Service
# ============================================================================

print_test "Verify Gateway Service is created"

GATEWAY_SERVICE=$(kubectl get svc -n envoy-gateway-system -l "gateway.envoyproxy.io/owning-gateway-name=migration-gateway,gateway.envoyproxy.io/owning-gateway-namespace=ingress-demo" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$GATEWAY_SERVICE" ]; then
    print_pass "Gateway Service created: $GATEWAY_SERVICE"

    # Get service type
    SERVICE_TYPE=$(kubectl get svc $GATEWAY_SERVICE -n envoy-gateway-system -o jsonpath='{.spec.type}')
    print_info "Service type: $SERVICE_TYPE"

    # Get ports
    PORTS=$(kubectl get svc $GATEWAY_SERVICE -n envoy-gateway-system -o jsonpath='{.spec.ports[*].port}')
    print_info "Exposed ports: $PORTS"
else
    print_fail "Gateway Service not found"
fi

# ============================================================================
# Test 9: Verify HTTPRoute Parent References
# ============================================================================

print_test "Verify HTTPRoute parent references"

for route in "${ROUTES[@]}"; do
    PARENT_REF=$(kubectl get httproute $route -n ingress-demo -o jsonpath='{.spec.parentRefs[0].name}')
    if [ "$PARENT_REF" = "migration-gateway" ]; then
        print_pass "HTTPRoute '$route' correctly references Gateway 'migration-gateway'"
    else
        print_fail "HTTPRoute '$route' has incorrect parent reference: $PARENT_REF"
    fi
done

# ============================================================================
# Test 10: Verify Backend References
# ============================================================================

print_test "Verify HTTPRoute backend references"

WEB_BACKENDS=$(kubectl get httproute web-routes -n ingress-demo -o jsonpath='{.spec.rules[*].backendRefs[*].name}' | grep -o web-service | wc -l)
if [ "$WEB_BACKENDS" -ge 1 ]; then
    print_pass "web-routes has correct backend references to web-service"
else
    print_fail "web-routes missing backend references"
fi

API_BACKENDS=$(kubectl get httproute api-routes -n ingress-demo -o jsonpath='{.spec.rules[*].backendRefs[*].name}' | grep -o api-service | wc -l)
if [ "$API_BACKENDS" -ge 1 ]; then
    print_pass "api-routes has correct backend references to api-service"
else
    print_fail "api-routes missing backend references"
fi

# ============================================================================
# Test 11: Port Forward and HTTP Test
# ============================================================================

print_test "Test HTTP connectivity through Gateway"

if [ -n "$GATEWAY_SERVICE" ]; then
    print_info "Setting up port-forward to Gateway Service..."

    # Kill any existing port-forwards
    pkill -f "port-forward.*$GATEWAY_SERVICE" 2>/dev/null || true
    sleep 2

    # Start port-forward in background
    kubectl port-forward -n envoy-gateway-system svc/$GATEWAY_SERVICE 18080:8080 >/dev/null 2>&1 &
    PF_PID=$!
    sleep 3

    # Test web-routes
    if curl -s -H "Host: web.example.com" http://localhost:18080/status/200 -o /dev/null -w "%{http_code}" | grep -q "200"; then
        print_pass "Successfully connected to web-routes (/status/200)"
    else
        print_fail "Failed to connect to web-routes"
    fi

    # Test api-routes
    if curl -s -H "Host: api.example.com" http://localhost:18080/v1/get -o /dev/null -w "%{http_code}" | grep -q "200"; then
        print_pass "Successfully connected to api-routes (/v1/get)"
    else
        print_fail "Failed to connect to api-routes"
    fi

    # Test prod-routes
    if curl -s -H "Host: prod.example.com" http://localhost:18080/ -o /dev/null -w "%{http_code}" | grep -q "200"; then
        print_pass "Successfully connected to prod-routes (/)"
    else
        print_fail "Failed to connect to prod-routes"
    fi

    # Cleanup port-forward
    kill $PF_PID 2>/dev/null || true
    print_info "Port-forward cleaned up"
else
    print_fail "Cannot test HTTP connectivity - Gateway Service not found"
fi

# ============================================================================
# TEST SUMMARY
# ============================================================================

print_header "TEST SUMMARY"

echo -e "${CYAN}Total Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo -e "${CYAN}The migration from Ingress to Gateway API is successful.${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ SOME TESTS FAILED${NC}"
    echo -e "${YELLOW}Please review the failed tests above.${NC}\n"
    exit 1
fi
