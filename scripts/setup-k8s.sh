#!/bin/bash
set -e

# Load versions
source "$(dirname "$0")/../versions.env"

echo "🚀 Setting up EnvoyGateway on existing Kubernetes cluster using Helm..."

# Check prerequisites
check_prerequisites() {
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ kubectl is not configured or cluster is not accessible"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        echo "❌ Helm is not installed. Please install it first:"
        echo "   https://helm.sh/docs/intro/install/"
        exit 1
    fi
}

check_prerequisites

# Get cluster info
echo "🔍 Current cluster info:"
kubectl cluster-info

# Install/Upgrade EnvoyGateway using Helm (OCI registry)
echo "�  Installing/Upgrading EnvoyGateway (${ENVOY_GATEWAY_VERSION}) using Helm..."
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
    --version ${ENVOY_GATEWAY_HELM_CHART_VERSION} \
    --namespace envoy-gateway-system \
    --create-namespace \
    --values deployments/helm/values.yaml \
    --wait

# Wait for EnvoyGateway to be ready
echo "⏳ Waiting for EnvoyGateway to be ready..."
kubectl wait --timeout=300s -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

# Create default EnvoyGateway GatewayClass
echo "🌐 Creating default EnvoyGateway GatewayClass..."
cat <<EOF | kubectl apply -f -
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF

echo "✅ Default GatewayClass 'eg' created"

# Install/Upgrade cert-manager
echo "� IInstalling/Upgrading cert-manager (${CERT_MANAGER_VERSION})..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version ${CERT_MANAGER_VERSION} \
    --set installCRDs=true \
    --set "extraArgs={--enable-gateway-api}" \
    --set "config.ingressShimConfig.extraCertificateAnnotations[0]=venafi.cert-manager.io/custom-fields" \
    --wait

# Wait for cert-manager to be ready
echo "⏳ Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=Available deployment/cert-manager-cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=300s

# Install cert-manager issuers
echo "📋 Installing cert-manager issuers..."
kubectl apply -f configs/cert-manager-issuers.yaml

# Wait for CA certificate to be ready
echo "⏳ Waiting for CA certificate to be ready..."
kubectl wait --for=condition=Ready certificate/selfsigned-ca -n cert-manager --timeout=300s



echo "✅ EnvoyGateway is ready on your Kubernetes cluster!"
echo "🔍 Cluster info:"
kubectl cluster-info

echo ""
echo "📊 Installed versions:"
echo "  EnvoyGateway: ${ENVOY_GATEWAY_VERSION}"
echo "  Gateway API: ${GATEWAY_API_VERSION}"
echo "  cert-manager: ${CERT_MANAGER_VERSION}"

echo ""
echo "📝 Verify installation:"
echo "   kubectl get pods -n envoy-gateway-system"
echo "   kubectl get gatewayclass"
echo ""
echo "🎯 Available GatewayClasses:"
kubectl get gatewayclass -o wide