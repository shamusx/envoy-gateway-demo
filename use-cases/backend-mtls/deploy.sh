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
echo "🧪 Testing the mTLS connection:"
echo ""
echo "1. Get the Gateway external IP:"
echo "   kubectl get gateway backend-mtls-gateway -n httpbin-tls -o jsonpath='{.status.addresses[0].value}'"
echo ""
echo "2. Add hostname to /etc/hosts (replace <GATEWAY_IP> with actual IP):"
echo "   echo '<GATEWAY_IP> mtls-backend.demo.int' | sudo tee -a /etc/hosts"
echo ""
echo "3. Test the mTLS connection with curl:"
echo "   curl -H 'Host: mtls-backend.demo.int' http://<GATEWAY_IP>:18080/get"
echo ""
echo "4. Test specific mTLS endpoints:"
echo "   curl -H 'Host: mtls-backend.demo.int' http://<GATEWAY_IP>:18080/status/200"
echo "   curl -H 'Host: mtls-backend.demo.int' http://<GATEWAY_IP>:18080/headers"
echo "   curl -H 'Host: mtls-backend.demo.int' http://<GATEWAY_IP>:18080/anything"
echo ""
echo "5. For port-forward testing (alternative):"
echo "   kubectl port-forward -n envoy-gateway-system svc/\$GATEWAY_SERVICE 18080:18080 &"
echo "   sleep 2"
echo "   curl -H 'Host: mtls-backend.demo.int' http://localhost:18080/get"
echo "   curl -H 'Host: mtls-backend.demo.int' http://localhost:18080/status/200"
echo ""
echo "6. Verify mTLS is working by checking backend logs:"
echo "   kubectl logs -n httpbin-tls deployment/httpbin-tls -f"
echo ""
echo "💡 The mTLS handshake happens between the Gateway and backend service."
echo "   Client requests to the Gateway use HTTP, while Gateway-to-backend uses mTLS."