#!/bin/bash
set -e

echo "🧹 Cleaning up EnvoyGateway from Kubernetes cluster..."

# Remove example configurations
echo "🗑️  Removing example configurations..."
kubectl delete -f examples/ --recursive --ignore-not-found=true

# Remove GatewayClass
echo "🗑️  Removing GatewayClass..."
kubectl delete -f configs/gatewayclass.yaml --ignore-not-found=true

# Uninstall EnvoyGateway using Helm
echo "🗑️  Uninstalling EnvoyGateway..."
helm uninstall eg -n envoy-gateway-system || true

# Remove namespace
echo "🗑️  Removing EnvoyGateway namespace..."
kubectl delete namespace envoy-gateway-system --ignore-not-found=true

# Uninstall cert-manager (optional - comment out if you want to keep it)
echo "🗑️  Uninstalling cert-manager..."
helm uninstall cert-manager -n cert-manager || true
kubectl delete namespace cert-manager --ignore-not-found=true

# Remove Gateway API CRDs (optional - comment out if you want to keep them)
echo "🗑️  Removing Gateway API CRDs..."
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml --ignore-not-found=true

echo "✅ EnvoyGateway cleanup completed!"