#!/bin/bash
set -e

CLUSTER_NAME=${1:-envoygateway-sandbox}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up EnvoyGateway sandbox environment...${NC}"

# Clean up task cache
if [ -d .task ]; then
    echo -e "${BLUE}🗑️  Removing task cache...${NC}"
    rm -rf .task
fi

# Delete Kind cluster
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${BLUE}🐳 Deleting Kind cluster: ${CLUSTER_NAME}${NC}"
    kind delete cluster --name ${CLUSTER_NAME}
    echo -e "${GREEN}✅ Kind cluster deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Kind cluster '${CLUSTER_NAME}' not found${NC}"
fi

# Clean up any port-forward processes
echo -e "${BLUE}🔌 Cleaning up port-forward processes...${NC}"
pkill -f "kubectl.*port-forward" || true

echo -e "${GREEN}🎉 Cleanup complete!${NC}"