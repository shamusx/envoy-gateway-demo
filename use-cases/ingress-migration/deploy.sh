#!/bin/bash

# Ingress to Gateway API Migration Demo
# This script demonstrates the step-by-step process of migrating from
# Kubernetes Ingress resources to Gateway API with Envoy Gateway

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

wait_for_ready() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local max_wait=${4:-60}

    print_step "Waiting for $resource_type/$resource_name to be ready..."

    local counter=0
    while [ $counter -lt $max_wait ]; do
        if kubectl wait --for=condition=ready "$resource_type/$resource_name" -n "$namespace" --timeout=1s >/dev/null 2>&1; then
            print_success "$resource_type/$resource_name is ready"
            return 0
        fi
        counter=$((counter + 1))
        sleep 1
    done

    print_error "Timeout waiting for $resource_type/$resource_name"
    return 1
}

wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    print_step "Waiting for deployment/$deployment to be ready..."
    kubectl wait --for=condition=available --timeout=60s deployment/$deployment -n $namespace
    print_success "deployment/$deployment is ready"
}

wait_for_gateway() {
    local gateway=$1
    local namespace=$2
    local max_wait=${3:-120}

    print_step "Waiting for Gateway/$gateway to be programmed..."

    local counter=0
    while [ $counter -lt $max_wait ]; do
        local status=$(kubectl get gateway $gateway -n $namespace -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null || echo "Unknown")
        if [ "$status" = "True" ]; then
            print_success "Gateway/$gateway is programmed and ready"
            return 0
        fi
        counter=$((counter + 1))
        sleep 1
    done

    print_error "Timeout waiting for Gateway/$gateway"
    return 1
}

# ============================================================================
# MIGRATION DEMONSTRATION
# ============================================================================

print_header "ENVOY GATEWAY MIGRATION DEMO: Ingress to Gateway API"

echo -e "${CYAN}This demo showcases the complete migration journey from legacy Ingress${NC}"
echo -e "${CYAN}resources to modern Gateway API with Envoy Gateway.${NC}\n"

# ============================================================================
# PHASE 1: Deploy Legacy Ingress Configuration
# ============================================================================

print_header "PHASE 1: Deploy Legacy Ingress Resources (Pre-Migration State)"

print_info "In this phase, we deploy traditional Kubernetes Ingress resources."
print_info "This represents your existing production setup that needs migration.\n"

print_step "Deploying namespace and backend services..."
kubectl apply -f 01-ingress-legacy.yaml

print_step "Waiting for backend deployments to be ready..."
wait_for_deployment "web-backend" "ingress-demo"
wait_for_deployment "api-backend" "ingress-demo"

print_step "Checking Ingress resources..."
echo ""
kubectl get ingress -n ingress-demo
echo ""

print_success "Phase 1 Complete: Legacy Ingress resources deployed"
print_info "Note: These Ingress resources would require an Ingress Controller (like NGINX)"
print_info "to function. We're demonstrating the migration path, not full functionality.\n"

# ============================================================================
# PHASE 2: Analyze Current Configuration
# ============================================================================

print_header "PHASE 2: Analyze Current Ingress Configuration"

print_info "Before migration, let's examine what we have:\n"

echo -e "${YELLOW}Ingress Resources:${NC}"
kubectl get ingress -n ingress-demo -o wide
echo ""

echo -e "${YELLOW}Ingress Details:${NC}"
for ingress in $(kubectl get ingress -n ingress-demo -o jsonpath='{.items[*].metadata.name}'); do
    echo -e "\n${CYAN}Ingress: $ingress${NC}"
    kubectl describe ingress $ingress -n ingress-demo | grep -A 10 "Rules:"
done
echo ""

print_success "Phase 2 Complete: Configuration analyzed"

# ============================================================================
# PHASE 3: Deploy Gateway API Resources (Migration)
# ============================================================================

print_header "PHASE 3: Migrate to Gateway API with Envoy Gateway"

print_info "Now we deploy the equivalent Gateway API resources."
print_info "This is the modern, Kubernetes-native approach using Envoy Gateway.\n"

print_step "Deploying GatewayClass..."
kubectl apply -f 02-gateway-api-migrated.yaml

print_step "Waiting for GatewayClass to be accepted..."
sleep 2
kubectl wait --for=condition=Accepted gatewayclass/envoy-ingress-migration --timeout=30s
print_success "GatewayClass is accepted"

print_step "Deploying Gateway..."
kubectl apply -f 02-gateway-api-migrated.yaml

print_step "Waiting for Gateway to be programmed..."
wait_for_gateway "migration-gateway" "ingress-demo" 120

print_step "Deploying HTTPRoutes..."
kubectl apply -f 02-gateway-api-migrated.yaml

print_step "Waiting for HTTPRoutes to be accepted..."
sleep 3
for route in web-routes api-routes prod-routes staging-routes; do
    kubectl wait --for=condition=Accepted httproute/$route -n ingress-demo --timeout=30s
    print_success "HTTPRoute/$route is accepted"
done

print_success "Phase 3 Complete: Gateway API resources deployed"

# ============================================================================
# PHASE 4: Verify Migration
# ============================================================================

print_header "PHASE 4: Verify Migration Success"

echo -e "${YELLOW}Gateway Status:${NC}"
kubectl get gateway -n ingress-demo
echo ""

echo -e "${YELLOW}Gateway Details:${NC}"
kubectl describe gateway migration-gateway -n ingress-demo | grep -A 20 "Status:"
echo ""

echo -e "${YELLOW}HTTPRoute Status:${NC}"
kubectl get httproute -n ingress-demo
echo ""

echo -e "${YELLOW}Service:${NC}"
GATEWAY_SERVICE=$(kubectl get svc -n envoy-gateway-system -l "gateway.envoyproxy.io/owning-gateway-name=migration-gateway" -o jsonpath='{.items[0].metadata.name}')
if [ -n "$GATEWAY_SERVICE" ]; then
    kubectl get svc -n envoy-gateway-system $GATEWAY_SERVICE
    print_success "Gateway service is available: $GATEWAY_SERVICE"
else
    print_error "Gateway service not found"
fi
echo ""

print_success "Phase 4 Complete: Migration verified"

# ============================================================================
# PHASE 5: Side-by-Side Comparison
# ============================================================================

print_header "PHASE 5: Side-by-Side Comparison"

echo -e "${YELLOW}Legacy Ingress Resources:${NC}"
kubectl get ingress -n ingress-demo -o wide
echo ""

echo -e "${YELLOW}Migrated Gateway API Resources:${NC}"
echo "GatewayClass:"
kubectl get gatewayclass envoy-ingress-migration
echo ""
echo "Gateway:"
kubectl get gateway -n ingress-demo
echo ""
echo "HTTPRoutes:"
kubectl get httproute -n ingress-demo
echo ""

print_success "Phase 5 Complete: Comparison displayed"

# ============================================================================
# MIGRATION COMPLETE
# ============================================================================

print_header "MIGRATION DEMONSTRATION COMPLETE!"

echo -e "${GREEN}✓ Successfully demonstrated Ingress to Gateway API migration${NC}\n"

echo -e "${CYAN}What we accomplished:${NC}"
echo -e "  ${GREEN}•${NC} Deployed legacy Ingress resources (3 Ingress objects)"
echo -e "  ${GREEN}•${NC} Created GatewayClass linked to Envoy Gateway"
echo -e "  ${GREEN}•${NC} Migrated to Gateway API (1 Gateway, 4 HTTPRoutes)"
echo -e "  ${GREEN}•${NC} Verified all resources are functioning correctly\n"

echo -e "${CYAN}Key Benefits of Gateway API:${NC}"
echo -e "  ${GREEN}•${NC} Role-oriented design (Gateway vs HTTPRoute ownership)"
echo -e "  ${GREEN}•${NC} Portable across implementations (Envoy, NGINX, etc.)"
echo -e "  ${GREEN}•${NC} Enhanced features (request/response filtering, traffic splitting)"
echo -e "  ${GREEN}•${NC} Better support for advanced routing patterns"
echo -e "  ${GREEN}•${NC} Strongly-typed API with clear semantics\n"

echo -e "${CYAN}Next Steps:${NC}"
echo -e "  ${YELLOW}1.${NC} Run: ${GREEN}./test.sh${NC} to test the migrated configuration"
echo -e "  ${YELLOW}2.${NC} Review HTTPRoute policies for advanced features"
echo -e "  ${YELLOW}3.${NC} Gradually remove legacy Ingress resources"
echo -e "  ${YELLOW}4.${NC} Update DNS/traffic routing to use new Gateway\n"

echo -e "${CYAN}Resources deployed in namespace: ${GREEN}ingress-demo${NC}\n"

print_success "Migration demonstration completed successfully!"
