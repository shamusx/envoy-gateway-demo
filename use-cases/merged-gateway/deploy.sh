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
echo "🧪 Quick Test:"
echo "============="
echo ""
echo "Test the merged gateway routes:"
echo ""
echo "  # Team A web traffic"
echo "  curl --resolve web-team-a.merged-gw.int:18080:127.0.0.1 http://web-team-a.merged-gw.int:18080/get"
echo ""
echo "  # Team A API traffic"
echo "  curl --resolve api-team-a.merged-gw.int:18080:127.0.0.1 http://api-team-a.merged-gw.int:18080/api/get"
echo ""
echo "  # Team B web traffic"
echo "  curl --resolve web-team-b.merged-gw.int:18080:127.0.0.1 http://web-team-b.merged-gw.int:18080/get"
echo ""
echo "  # Team B API traffic"
echo "  curl --resolve api-team-b.merged-gw.int:18080:127.0.0.1 http://api-team-b.merged-gw.int:18080/api/get"
echo ""
echo "💡 These use --resolve to test against localhost (kind cluster) without port-forwarding"
echo "💡 Both teams share a single EnvoyProxy deployment with separate routing rules"
echo ""