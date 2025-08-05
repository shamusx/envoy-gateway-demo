#!/bin/bash
set -e

echo "🚀 Deploying httpbin demo application..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Deploy httpbin
echo "📦 Deploying httpbin application..."
kubectl apply -f examples/httpbin/deployment.yaml
kubectl apply -f examples/httpbin/gateway.yaml
kubectl apply -f examples/httpbin/httproute.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for httpbin deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/httpbin -n httpbin

# Wait for gateway to be ready
echo "⏳ Waiting for gateway to be ready..."
kubectl wait --for=condition=Programmed --timeout=300s gateway/httpbin-gateway -n httpbin

echo "✅ httpbin deployment completed!"

echo ""
echo "🔍 Deployment status:"
kubectl get pods -n httpbin
kubectl get gateway -n httpbin
kubectl get httproute -n httpbin

echo ""
echo "📝 Testing instructions:"
echo "1. Get gateway address:"
echo "   kubectl get gateway httpbin-gateway -n httpbin -o jsonpath='{.status.addresses[0].value}'"
echo ""
echo "2. Test with curl:"
echo "   GATEWAY_IP=\$(kubectl get gateway httpbin-gateway -n httpbin -o jsonpath='{.status.addresses[0].value}')"
echo "   curl -H \"Host: httpbin.int\" http://\$GATEWAY_IP/get"
echo ""
echo "3. Or use port-forward for local testing:"
echo "   kubectl port-forward -n envoy-gateway-system service/envoy-gateway 8080:80"
echo "   curl -H \"Host: httpbin.int\" http://localhost:8080/get"