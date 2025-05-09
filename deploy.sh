#!/bin/bash

# Exit on any error
set -e

echo "=== PTFD Application K3s Deployment Script ==="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

echo "=== Configuring Nginx Ingress Controller for NodePort ==="
kubectl apply -f nginx-ingress-nodeport.yaml

echo "=== Applying Kubernetes Manifests ==="
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f certificate.yaml
kubectl apply -f ingress.yaml

echo "=== Waiting for Pods to be Ready ==="
kubectl wait --for=condition=ready pod -l app=ptfd-app --timeout=300s

echo "=== Deployment Status ==="
echo "Pods:"
kubectl get pods -l app=ptfd-app

echo "Service:"
kubectl get svc ptfd-app

echo "Ingress:"
kubectl get ingress ptfd-app-ingress

echo "Certificate:"
kubectl get certificate dashboard-arcadiasmw-tls

echo ""
echo "=== Nginx Ingress Controller Status ==="
kubectl get svc -n ingress-nginx

echo "=== Deployment Complete ==="
echo "You can access your application at: https://dashboard.arcadiasmw.com"
echo "If using NodePort, access at: https://dashboard.arcadiasmw.com:30443"
echo "Note: It may take a few minutes for the DNS and certificate to propagate."
