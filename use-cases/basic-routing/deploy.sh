#!/bin/bash
set -e

echo "🚀 Deploying Basic Routing Use Case..."

# Check if httpbin is deployed
if ! kubectl get namespace httpbin &> /dev/null; then
    echo "📦 Deploying httpbin first..."
    kubectl create namespace httpbin
    kubectl apply -f ../../examples/httpbin/deployment.yaml -n httpbin
    kubectl wait --for=condition=Available deployment/httpbin -n httpbin --timeout=300s
fi

# Deploy Gateway
echo "🌐 Creating Gateway..."
kubectl apply -f gateway.yaml

# Deploy HTTPRoutes
echo "🛣️  Creating HTTPRoutes..."
kubectl apply -f httproute.yaml

# Wait for gateway to be ready
echo "⏳ Waiting for gateway to be ready..."
sleep 5

echo "✅ Basic Routing use case deployed successfully!"
echo ""
echo "📊 Status:"
echo "  Gateway:"
kubectl get gateway -n httpbin httpbin-gateway
echo ""
echo "  HTTPRoutes:"
kubectl get httproute -n httpbin
echo ""
echo "  Gateway Service:"
GATEWAY_SERVICE=$(kubectl get service -n httpbin -l gateway.envoyproxy.io/owning-gateway-name=httpbin-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [[ -n "$GATEWAY_SERVICE" ]]; then
    kubectl get service -n httpbin $GATEWAY_SERVICE
else
    echo "  ⏳ Gateway service is being created..."
fi

echo ""
echo "🧪 Quick Test:"
echo "============="
echo ""
echo "Port-forward to test the routes:"
echo ""
echo "  # Start port-forward"
echo "  kubectl port-forward -n httpbin service/\$(kubectl get service -n httpbin -l gateway.envoyproxy.io/owning-gateway-name=httpbin-gateway -o jsonpath='{.items[0].metadata.name}') 8080:8080 &"
echo ""
echo "  # Test different paths"
echo "  curl http://localhost:8080/get"
echo "  curl http://localhost:8080/headers"
echo "  curl http://localhost:8080/status/200"
echo "  curl http://localhost:8080/status/404"
echo "  curl -X POST http://localhost:8080/anything -d '{\"test\": \"data\"}'"
echo "  curl http://localhost:8080/ip"
echo ""
echo "💡 Run './test.sh' for automated testing"
echo ""
