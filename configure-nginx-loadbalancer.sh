#!/bin/bash

# Exit on any error
set -e

echo "=== Configuring Nginx Ingress Controller with LoadBalancer ==="
echo "This will allow the ingress controller to be accessed without specifying a port number"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Apply the LoadBalancer configuration
echo "Applying LoadBalancer configuration to Nginx ingress controller..."
kubectl apply -f nginx-ingress-loadbalancer.yaml

# Wait for the external IP to be assigned
echo "Waiting for external IP to be assigned (this may take a few minutes)..."
external_ip=""
while [ -z $external_ip ]; do
    echo "Waiting for external IP..."
    external_ip=$(kubectl get svc ingress-nginx-controller -n ingress-nginx --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    [ -z "$external_ip" ] && sleep 10
done

# Verify the configuration
echo "Verifying Nginx ingress controller configuration..."
echo "Pods:"
kubectl get pods -n ingress-nginx

echo "Services:"
kubectl get svc -n ingress-nginx

echo ""
echo "=== Configuration Complete ==="
echo "The Nginx ingress controller is now configured with a LoadBalancer"
echo "External IP: $external_ip"
echo ""
echo "Important: Update your DNS to point dashboard.arcadiasmw.com to $external_ip"
echo "You can then access your application at: https://dashboard.arcadiasmw.com"
echo "(without specifying the port number)"
