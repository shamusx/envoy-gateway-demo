#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing HTTP-to-HTTPS Redirect with Wildcard SSL${NC}"
echo "====================================================="

# Test HTTP-to-HTTPS redirect
echo -e "${BLUE}Test 1: HTTP-to-HTTPS redirect${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --resolve web.httpbin.io:8080:127.0.0.1 http://web.httpbin.io:8080/get)
if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
    echo -e "${GREEN}✅ HTTP redirect working (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}❌ Expected 301/302 redirect, got HTTP $HTTP_CODE${NC}"
fi

echo ""

# Test HTTPS endpoint
echo -e "${BLUE}Test 2: HTTPS endpoint${NC}"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k --resolve web.httpbin.io:8443:127.0.0.1 https://web.httpbin.io:8443/get)
if [ "$HTTPS_CODE" = "200" ]; then
    echo -e "${GREEN}✅ HTTPS endpoint working (HTTP $HTTPS_CODE)${NC}"
else
    echo -e "${RED}❌ Expected 200, got HTTP $HTTPS_CODE${NC}"
fi

echo ""
echo -e "${BLUE}Tests complete.${NC}"
