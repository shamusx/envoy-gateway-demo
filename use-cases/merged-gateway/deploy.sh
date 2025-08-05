#!/bin/bash
set -e

echo "🚀 Deploying Merged Gateway Use Case..."

# Check if httpbin is deployed
if ! kubectl get namespace httpbin &> /dev/null; then
    echo "📦 Deploying httpbin first..."
    kubectl apply -f ../../examples/httpbin/deployment.yaml -n httpbin
    kubectl wait --for=condition=Available deployment/httpbin -n httpbin --timeout=300s
fi

# Note: mergeGateways is configured in the EnvoyProxy CR, not EnvoyGateway config

# Deploy GatewayClass and EnvoyProxy configuration
echo "🏗️  Creating GatewayClass with merged gateway support..."
kubectl apply -f gatewayclass.yaml

# Deploy Gateways for both teams
echo "🌐 Creating Gateways for Team A and Team B..."
kubectl apply -f gateways.yaml

# Deploy HTTPRoutes
echo "🛣️  Creating HTTPRoutes..."
kubectl apply -f httproutes.yaml

# Deploy ReferenceGrants
echo "🛣️  Creating ReferenceGrants..."
kubectl apply -f referencegrants.yaml

# Wait for gateways to be ready
echo "⏳ Waiting for gateways to be ready..."

echo "✅ Merged Gateway use case deployed successfully!"
echo ""
echo "📊 Status:"
echo "  Gateways:"
kubectl get gateway -A
echo ""
echo "  HTTPRoutes:"
kubectl get httproute -A
echo ""
echo "  EnvoyProxy deployments (should see merged deployment):"
kubectl get deployment -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name

echo ""
echo "🧪 Testing Instructions:"
echo "===================="
echo ""
echo "1. Get the Gateway external IP or set up port forwarding:"
echo "   # Option A: External IP (if LoadBalancer available)"
echo "   GATEWAY_IP=\$(kubectl get gateway team-a-gateway -n team-a -o jsonpath='{.status.addresses[0].value}')"
echo "   echo \"Gateway IP: \$GATEWAY_IP\""
echo ""
echo "   # Option B: Port forwarding (recommended for local testing)"
echo "   GATEWAY_SERVICE=\$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-namespace=team-a -o jsonpath='{.items[0].metadata.name}')"
echo "   kubectl port-forward -n envoy-gateway-system service/\$GATEWAY_SERVICE 18080:18080 &"
echo "   sleep 2"
echo ""
echo "2. Add hostnames to /etc/hosts (for external IP testing):"
echo "   echo \"\$GATEWAY_IP web-team-a.merged-gw.int\" | sudo tee -a /etc/hosts"
echo "   echo \"\$GATEWAY_IP api-team-a.merged-gw.int\" | sudo tee -a /etc/hosts"
echo "   echo \"\$GATEWAY_IP web-team-b.merged-gw.int\" | sudo tee -a /etc/hosts"
echo "   echo \"\$GATEWAY_IP api-team-b.merged-gw.int\" | sudo tee -a /etc/hosts"
echo ""
echo "3. Test the merged gateway routes:"
echo ""
echo "   # Test Team A web traffic"
echo "   curl -H \"Host: web-team-a.merged-gw.int\" http://localhost:18080/get"
echo ""
echo "   # Test Team A API traffic"
echo "   curl -H \"Host: api-team-a.merged-gw.int\" http://localhost:18080/api/get"
echo ""
echo "   # Test Team B web traffic"
echo "   curl -H \"Host: web-team-b.merged-gw.int\" http://localhost:18080/get"
echo ""
echo "   # Test Team B API traffic"
echo "   curl -H \"Host: api-team-b.merged-gw.int\" http://localhost:18080/api/get"
echo ""
echo "4. Test different endpoints to verify routing:"
echo "   curl -H \"Host: web-team-a.merged-gw.int\" http://localhost:18080/status/200"
echo "   curl -H \"Host: api-team-b.merged-gw.int\" http://localhost:18080/api/headers"
echo ""
echo "5. Verify merged deployment (both teams should share the same EnvoyProxy):"
echo "   kubectl get deployment -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name"
echo "   echo \"Expected: Single deployment serving both team gateways\""
echo ""
echo "6. Check gateway status and addresses:"
echo "   kubectl get gateway -A -o wide"
echo ""
echo "7. View EnvoyProxy configuration (optional):"
echo "   kubectl get envoyproxy -A -o yaml"
echo ""
echo "✅ The merged gateway configuration allows both teams to share a single"
echo "   EnvoyProxy deployment while maintaining separate routing rules and hostnames."