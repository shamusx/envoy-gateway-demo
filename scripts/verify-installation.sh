#!/bin/bash

echo "📊 EnvoyGateway Status Check"
echo "=========================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Connected to cluster:"
kubectl cluster-info --context $(kubectl config current-context) | head -1

echo ""
echo "🔍 EnvoyGateway Components:"
echo "-------------------------"

# Check EnvoyGateway namespace
if kubectl get namespace envoy-gateway-system &> /dev/null; then
    echo "✅ Namespace: envoy-gateway-system exists"
    
    # Check EnvoyGateway deployment
    if kubectl get deployment envoy-gateway -n envoy-gateway-system &> /dev/null; then
        echo "✅ EnvoyGateway deployment found"
        kubectl get deployment envoy-gateway -n envoy-gateway-system
    else
        echo "❌ EnvoyGateway deployment not found"
    fi
    
    # Check pods
    echo ""
    echo "📦 Pods in envoy-gateway-system:"
    kubectl get pods -n envoy-gateway-system
    
else
    echo "❌ Namespace envoy-gateway-system not found"
fi

echo ""
echo "🚪 Gateway Classes:"
echo "------------------"
kubectl get gatewayclass 2>/dev/null || echo "❌ No GatewayClasses found"

echo ""
echo "🌐 Gateways:"
echo "-----------"
kubectl get gateway -A 2>/dev/null || echo "ℹ️  No Gateways found"

echo ""
echo "🛣️  HTTPRoutes:"
echo "--------------"
kubectl get httproute -A 2>/dev/null || echo "ℹ️  No HTTPRoutes found"

echo ""
echo "🔐 cert-manager:"
echo "---------------"
if kubectl get namespace cert-manager &> /dev/null; then
    echo "✅ cert-manager namespace exists"
    kubectl get pods -n cert-manager
else
    echo "❌ cert-manager not found"
fi

echo ""
echo "📋 Gateway API CRDs:"
echo "-------------------"
kubectl get crd | grep gateway.networking.k8s.io || echo "❌ Gateway API CRDs not found"