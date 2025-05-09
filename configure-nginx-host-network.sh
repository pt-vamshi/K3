#!/bin/bash

# Exit on any error
set -e

echo "=== Configuring Nginx Ingress Controller to use Host Network ==="
echo "This will allow the ingress controller to bind directly to ports 80 and 443 on the host"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Apply the host network configuration
echo "Applying host network configuration to Nginx ingress controller..."
kubectl apply -f nginx-ingress-host-network.yaml

# Restart the Nginx ingress controller
echo "Restarting Nginx ingress controller to apply changes..."
kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx

# Wait for the Nginx ingress controller to be ready
echo "Waiting for Nginx ingress controller to be ready..."
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=120s

# Verify the configuration
echo "Verifying Nginx ingress controller configuration..."
echo "Pods:"
kubectl get pods -n ingress-nginx

echo "Services:"
kubectl get svc -n ingress-nginx

echo ""
echo "=== Configuration Complete ==="
echo "The Nginx ingress controller is now configured to use host network"
echo "You can access your application at: https://dashboard.arcadiasmw.com"
echo "(without specifying the port number)"
echo ""
echo "Note: Make sure your firewall allows traffic on ports 80 and 443"
