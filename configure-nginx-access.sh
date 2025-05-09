#!/bin/bash

# Exit on any error
set -e

echo "=== Configure Nginx Ingress Controller Access ==="
echo "This script provides multiple options to access your application without specifying a port number"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Display menu
echo "Please select an option:"
echo "1) Use hostNetwork (recommended for Hetzner servers)"
echo "2) Use NodePort with iptables port forwarding"
echo "3) Install MetalLB for LoadBalancer support"
echo "4) Exit"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo "=== Configuring Nginx Ingress Controller with hostNetwork ==="
        echo "This will allow the ingress controller to bind directly to ports 80 and 443 on the host"
        echo ""
        
        # Apply the host network configuration
        echo "Applying host network configuration to Nginx ingress controller..."
        kubectl patch deployment ingress-nginx-controller -n ingress-nginx --patch '{"spec": {"template": {"spec": {"hostNetwork": true, "dnsPolicy": "ClusterFirstWithHostNet"}}}}'
        
        # Restart the Nginx ingress controller
        echo "Restarting Nginx ingress controller to apply changes..."
        kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
        
        # Wait for the Nginx ingress controller to be ready
        echo "Waiting for Nginx ingress controller to be ready..."
        kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=120s
        
        # Get the server's external IP
        server_ip=$(curl -s ifconfig.me)
        
        echo ""
        echo "=== Configuration Complete ==="
        echo "The Nginx ingress controller is now configured to use host network"
        echo "Your server's external IP is: $server_ip"
        echo ""
        echo "Important: Update your DNS to point dashboard.arcadiasmw.com to $server_ip"
        echo "You can then access your application at: https://dashboard.arcadiasmw.com"
        echo "(without specifying the port number)"
        echo ""
        echo "Note: Make sure your firewall allows traffic on ports 80 and 443"
        ;;
        
    2)
        echo "=== Configuring Nginx Ingress Controller with NodePort and Port Forwarding ==="
        echo "This will redirect traffic from standard ports (80/443) to NodePort ports"
        echo ""
        
        # Apply the NodePort configuration
        echo "Applying NodePort configuration to Nginx ingress controller..."
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: NodePort
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    nodePort: 30443
    protocol: TCP
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
EOF
        
        # Check if running as root
        if [ "$EUID" -ne 0 ]; then
          echo "Port forwarding requires root privileges. Please run this script with sudo."
          exit 1
        fi
        
        # Save current iptables rules
        iptables-save > /tmp/iptables.backup
        echo "Current iptables rules backed up to /tmp/iptables.backup"
        
        # Set up port forwarding
        echo "Setting up port forwarding rules..."
        iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080
        iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 30443
        
        # For localhost connections
        iptables -t nat -A OUTPUT -p tcp -d localhost --dport 80 -j REDIRECT --to-port 30080
        iptables -t nat -A OUTPUT -p tcp -d localhost --dport 443 -j REDIRECT --to-port 30443
        
        echo "Port forwarding rules added successfully"
        
        # Make iptables rules persistent (for Ubuntu)
        if command -v netfilter-persistent &> /dev/null; then
          echo "Saving iptables rules to make them persistent..."
          netfilter-persistent save
          echo "Rules saved successfully"
        else
          echo "WARNING: netfilter-persistent not found. Rules will not persist after reboot."
          echo "To install: sudo apt-get install iptables-persistent"
        fi
        
        # Get the server's external IP
        server_ip=$(curl -s ifconfig.me)
        
        echo ""
        echo "=== Configuration Complete ==="
        echo "The Nginx ingress controller is now configured with NodePort and port forwarding"
        echo "Your server's external IP is: $server_ip"
        echo ""
        echo "Important: Update your DNS to point dashboard.arcadiasmw.com to $server_ip"
        echo "You can then access your application at: https://dashboard.arcadiasmw.com"
        echo "(without specifying the port number)"
        ;;
        
    3)
        echo "=== Installing MetalLB for LoadBalancer Support ==="
        echo "This will provide LoadBalancer functionality in your bare-metal environment"
        echo ""
        
        # Install MetalLB
        echo "Installing MetalLB..."
        kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
        
        # Wait for MetalLB to be ready
        echo "Waiting for MetalLB to be ready..."
        kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=120s
        
        # Get the server's external IP
        server_ip=$(curl -s ifconfig.me)
        
        # Configure MetalLB address pool
        echo "Configuring MetalLB address pool..."
        cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $server_ip/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advert
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
        
        # Configure Nginx ingress controller to use LoadBalancer
        echo "Configuring Nginx ingress controller to use LoadBalancer..."
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/component: controller
EOF
        
        echo ""
        echo "=== Configuration Complete ==="
        echo "MetalLB is now installed and configured to provide LoadBalancer functionality"
        echo "The Nginx ingress controller is now configured to use LoadBalancer"
        echo "Your server's external IP is: $server_ip"
        echo ""
        echo "Important: Update your DNS to point dashboard.arcadiasmw.com to $server_ip"
        echo "You can then access your application at: https://dashboard.arcadiasmw.com"
        echo "(without specifying the port number)"
        ;;
        
    4)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac
