#!/bin/bash

# Ingress to Gateway API Conversion using ingress2gateway Tool
# This script demonstrates using the ingress2gateway utility to automatically
# convert existing Ingress resources to Gateway API format

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

# Check if ingress2gateway is installed
check_ingress2gateway() {
    if ! command -v ingress2gateway >/dev/null 2>&1; then
        print_error "ingress2gateway tool not found!"
        echo ""
        echo -e "${YELLOW}Installation instructions:${NC}"
        echo ""
        echo -e "${CYAN}macOS:${NC}"
        echo "  brew install kubernetes-sigs/ingress2gateway/ingress2gateway"
        echo ""
        echo -e "${CYAN}Linux:${NC}"
        echo "  # Download latest release from:"
        echo "  # https://github.com/kubernetes-sigs/ingress2gateway/releases"
        echo ""
        echo -e "${CYAN}From source:${NC}"
        echo "  git clone https://github.com/kubernetes-sigs/ingress2gateway.git"
        echo "  cd ingress2gateway"
        echo "  make build"
        echo "  sudo mv bin/ingress2gateway /usr/local/bin/"
        echo ""
        echo -e "${CYAN}Or run:${NC}"
        echo "  task install-deps  # (from repository root)"
        echo ""
        exit 1
    fi

    print_success "ingress2gateway tool found"
    local version=$(ingress2gateway version 2>/dev/null || echo "unknown")
    print_info "Version: $version"
}

# ============================================================================
# MAIN DEMONSTRATION
# ============================================================================

print_header "INGRESS2GATEWAY CONVERSION TOOL DEMONSTRATION"

echo -e "${CYAN}This script demonstrates using the ingress2gateway utility to automatically${NC}"
echo -e "${CYAN}convert Kubernetes Ingress resources to Gateway API format.${NC}\n"

# ============================================================================
# Step 1: Verify Prerequisites
# ============================================================================

print_header "Step 1: Verify Prerequisites"

check_ingress2gateway

print_step "Checking kubectl connectivity..."
if ! kubectl cluster-info >/dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
print_success "Connected to Kubernetes cluster"

# ============================================================================
# Step 2: Deploy Legacy Ingress Resources
# ============================================================================

print_header "Step 2: Deploy Legacy Ingress Resources"

print_step "Deploying sample Ingress resources..."
kubectl apply -f 01-ingress-legacy.yaml

print_step "Waiting for resources to be ready..."
sleep 5

print_step "Verifying Ingress resources..."
kubectl get ingress -n ingress-demo
echo ""

print_success "Legacy Ingress resources deployed"

# ============================================================================
# Step 3: Convert Using ingress2gateway
# ============================================================================

print_header "Step 3: Convert Ingress to Gateway API Using ingress2gateway"

print_info "The ingress2gateway tool can operate in two modes:"
echo -e "  ${YELLOW}1.${NC} Print mode: Converts resources from cluster"
echo -e "  ${YELLOW}2.${NC} File mode: Converts resources from YAML files"
echo ""

# Method 1: Convert from cluster
print_step "Method 1: Converting from cluster (reading live Ingress resources)..."
echo ""

print_info "Running: ingress2gateway print --namespace=ingress-demo"
echo ""

# Create output directory
mkdir -p converted-output

# Run ingress2gateway and save output
if ingress2gateway print --namespace=ingress-demo > converted-output/from-cluster.yaml 2>&1; then
    print_success "Conversion from cluster completed"
    echo ""
    echo -e "${YELLOW}Generated Gateway API resources (preview):${NC}"
    echo "────────────────────────────────────────────────────────────────"
    head -n 50 converted-output/from-cluster.yaml
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    print_info "Full output saved to: converted-output/from-cluster.yaml"
else
    print_info "Cluster-based conversion encountered issues (this is expected if provider-specific resources exist)"
fi

echo ""

# Method 2: Convert from files
print_step "Method 2: Converting from YAML files..."
echo ""

print_info "Running: ingress2gateway print --input-file=01-ingress-legacy.yaml"
echo ""

if ingress2gateway print --input-file=01-ingress-legacy.yaml > converted-output/from-file.yaml 2>&1; then
    print_success "Conversion from file completed"
    echo ""
    echo -e "${YELLOW}Generated Gateway API resources (preview):${NC}"
    echo "────────────────────────────────────────────────────────────────"
    head -n 50 converted-output/from-file.yaml
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    print_info "Full output saved to: converted-output/from-file.yaml"
else
    print_error "File-based conversion failed"
fi

# ============================================================================
# Step 4: Compare Outputs
# ============================================================================

print_header "Step 4: Compare Conversion Outputs"

print_info "Let's examine what ingress2gateway generated..."
echo ""

echo -e "${YELLOW}Key Gateway API Resources Created:${NC}"
echo ""

# Count resources
if [ -f converted-output/from-file.yaml ]; then
    GATEWAYCLASSES=$(grep -c "kind: GatewayClass" converted-output/from-file.yaml 2>/dev/null || echo 0)
    GATEWAYS=$(grep -c "kind: Gateway" converted-output/from-file.yaml 2>/dev/null || echo 0)
    HTTPROUTES=$(grep -c "kind: HTTPRoute" converted-output/from-file.yaml 2>/dev/null || echo 0)

    echo -e "  ${GREEN}•${NC} GatewayClass resources: $GATEWAYCLASSES"
    echo -e "  ${GREEN}•${NC} Gateway resources: $GATEWAYS"
    echo -e "  ${GREEN}•${NC} HTTPRoute resources: $HTTPROUTES"
    echo ""
fi

# ============================================================================
# Step 5: Explain the Transformation
# ============================================================================

print_header "Step 5: Understanding the Transformation"

echo -e "${CYAN}What ingress2gateway does:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} ${YELLOW}Analyzes Ingress Resources${NC}"
echo -e "     • Reads Ingress objects from cluster or files"
echo -e "     • Parses rules, paths, hosts, and backends"
echo -e "     • Extracts annotations for special features"
echo ""
echo -e "  ${GREEN}2.${NC} ${YELLOW}Creates GatewayClass${NC}"
echo -e "     • Defines which Gateway controller to use"
echo -e "     • Sets up the infrastructure layer"
echo ""
echo -e "  ${GREEN}3.${NC} ${YELLOW}Generates Gateway Resources${NC}"
echo -e "     • Creates listeners for each unique host"
echo -e "     • Maps Ingress hosts to Gateway listeners"
echo -e "     • Configures protocols and ports"
echo ""
echo -e "  ${GREEN}4.${NC} ${YELLOW}Produces HTTPRoute Resources${NC}"
echo -e "     • Converts path rules to HTTPRoute matches"
echo -e "     • Translates annotations to native filters"
echo -e "     • Maps backend services to backendRefs"
echo ""
echo -e "  ${GREEN}5.${NC} ${YELLOW}Handles Special Cases${NC}"
echo -e "     • Converts rewrite rules to URLRewrite filters"
echo -e "     • Manages TLS configurations"
echo -e "     • Preserves path matching types"
echo ""

# ============================================================================
# Step 6: Side-by-Side Comparison
# ============================================================================

print_header "Step 6: Side-by-Side Comparison"

echo -e "${CYAN}Original Ingress Configuration:${NC}"
echo "────────────────────────────────────────────────────────────────"
cat 01-ingress-legacy.yaml | grep -A 20 "kind: Ingress" | head -n 30
echo "..."
echo "────────────────────────────────────────────────────────────────"
echo ""

if [ -f converted-output/from-file.yaml ]; then
    echo -e "${CYAN}Converted Gateway API Configuration:${NC}"
    echo "────────────────────────────────────────────────────────────────"
    cat converted-output/from-file.yaml | grep -A 20 "kind: Gateway" | head -n 30
    echo "..."
    echo "────────────────────────────────────────────────────────────────"
fi

# ============================================================================
# Step 7: Deployment Options
# ============================================================================

print_header "Step 7: Deployment Options"

echo -e "${YELLOW}Option 1: Deploy Auto-Generated Resources${NC}"
echo -e "  kubectl apply -f converted-output/from-file.yaml"
echo ""

echo -e "${YELLOW}Option 2: Deploy Pre-Configured Resources (Recommended)${NC}"
echo -e "  kubectl apply -f 02-gateway-api-migrated.yaml"
echo ""

echo -e "${CYAN}The pre-configured resources (02-gateway-api-migrated.yaml) are recommended${NC}"
echo -e "${CYAN}because they include:${NC}"
echo -e "  ${GREEN}•${NC} Proper GatewayClass configuration for Envoy Gateway"
echo -e "  ${GREEN}•${NC} Optimized listener setup"
echo -e "  ${GREEN}•${NC} Clean HTTPRoute organization"
echo -e "  ${GREEN}•${NC} Correct namespace references"
echo ""

# ============================================================================
# Step 8: Cleanup Options
# ============================================================================

print_header "Demonstration Complete!"

echo -e "${GREEN}✓ Successfully demonstrated ingress2gateway conversion${NC}\n"

echo -e "${CYAN}What we learned:${NC}"
echo -e "  ${GREEN}•${NC} How to install and use ingress2gateway"
echo -e "  ${GREEN}•${NC} Two conversion methods: cluster-based and file-based"
echo -e "  ${GREEN}•${NC} Understanding the transformation process"
echo -e "  ${GREEN}•${NC} Comparing Ingress vs Gateway API configurations"
echo ""

echo -e "${CYAN}Next Steps:${NC}"
echo -e "  ${YELLOW}1.${NC} Review converted resources in: ${GREEN}converted-output/${NC}"
echo -e "  ${YELLOW}2.${NC} Deploy Gateway API resources: ${GREEN}./deploy.sh${NC}"
echo -e "  ${YELLOW}3.${NC} Test the migration: ${GREEN}./test.sh${NC}"
echo -e "  ${YELLOW}4.${NC} Read the full guide: ${GREEN}README.md${NC}"
echo ""

echo -e "${YELLOW}Keep or Clean up conversion outputs?${NC}"
echo -e "  Keep for reference: ${GREEN}ls converted-output/${NC}"
echo -e "  Clean up: ${GREEN}rm -rf converted-output/${NC}"
echo ""

print_success "ingress2gateway demonstration completed successfully!"
