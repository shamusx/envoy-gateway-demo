#!/bin/bash
set -e

echo "🚀 Deploying Backend mTLS Use Case..."

# Check if httpbin-tls is deployed
if ! kubectl get namespace httpbin-tls &> /dev/null; then
    echo "📦 Deploying httpbin-tls first..."
    kubectl apply -f ../../examples/httpbin-tls/deployment.yaml
    echo "⏳ Waiting for httpbin-tls certificate to be ready..."
    kubectl wait --for=condition=Ready certificate/httpbin-tls-cert -n httpbin-tls --timeout=300s
    
    # Copy CA certificate to httpbin-tls namespace for client cert validation
    echo "⏳ Waiting for httpbin-tls deployment to be ready..."
fi

# Deploy certificates for mTLS
echo "🔐 Creating certificates for mTLS..."
kubectl apply -f certificates.yaml

# Wait for certificates to be ready
echo "⏳ Waiting for certificates to be ready..."

# Deploy Gateway and HTTPRoute
echo "🌐 Creating Gateway and HTTPRoute..."
kubectl apply -f gateway.yaml

# Wait for gateway to be ready
echo "⏳ Waiting for gateway to be ready..."

# Deploy BackendTLSPolicy
echo "🔒 Creating BackendTLSPolicy for mTLS..."
kubectl apply -f backend-tls-policy.yaml

echo "✅ Backend mTLS use case deployed successfully!"
echo ""
echo "📊 Status:"
echo "  Certificates:"
kubectl get certificate -n httpbin-tls
echo ""
echo "  Gateway:"
kubectl get gateway -n httpbin-tls
echo ""
echo "  HTTPRoute:"
kubectl get httproute -n httpbin-tls
echo ""
echo "  BackendTLSPolicy:"
kubectl get backendtlspolicy -n httpbin-tls

echo ""
echo "🧪 Quick Test:"
echo "============="
echo ""
echo "Test the backend mTLS connection:"
echo ""
echo "  curl --resolve mtls-backend.demo.int:18080:127.0.0.1 http://mtls-backend.demo.int:18080/get"
echo ""
echo "💡 This uses --resolve to test against localhost (kind cluster) without port-forwarding"
echo "💡 The mTLS handshake happens between Gateway and backend - client uses HTTP"
echo ""