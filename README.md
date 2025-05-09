# PTFD Application K3s Deployment

This repository contains all the necessary files to deploy the PTFD application (ghcr.io/1308harshit/ptfd:latest) to K3s with Nginx ingress and SSL certificates.

## Prerequisites

- K3s cluster up and running on your Ubuntu machine
- kubectl configured to communicate with your K3s cluster
- Domain name (dashboard.arcadiasmw.com) pointing to your Ubuntu machine's IP address where K3s is installed

### Installing Required Components

#### 1. Install Nginx Ingress Controller

If you don't have the Nginx ingress controller installed, you can install it with:

```bash
# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Verify the installation
kubectl get pods -n ingress-nginx
```

Wait until the ingress-nginx-controller pod is in the Running state.

##### Configure Nginx Ingress Controller for NodePort

Since you're running on a bare-metal Ubuntu machine, the LoadBalancer service type might show `<pending>` for EXTERNAL-IP. To fix this, apply the NodePort configuration:

```bash
# Apply the NodePort configuration for Nginx Ingress Controller
kubectl apply -f nginx-ingress-nodeport.yaml

# Verify the service is now using NodePort
kubectl get svc -n ingress-nginx
```

This will expose the Nginx Ingress Controller on your Ubuntu machine's IP address at ports 30080 (HTTP) and 30443 (HTTPS).

#### 2. Install cert-manager

If you don't have cert-manager installed, you can install it with:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Verify the installation
kubectl get pods -n cert-manager
```

Wait until all cert-manager pods are in the Running state.

## Deployment Steps

### 1. Deploy the Application

You can deploy the application using the provided script:

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

Or manually apply the Kubernetes manifests:

```bash
# Apply the Kubernetes manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f certificate.yaml
kubectl apply -f ingress.yaml
```

### 2. Verify the Deployment

```bash
# Check if the pods are running
kubectl get pods -l app=ptfd-app

# Check if the service is created
kubectl get svc ptfd-app

# Check if the certificate is issued
kubectl get certificate dashboard-arcadiasmw-tls

# Check if the ingress is configured
kubectl get ingress ptfd-app-ingress
```

### 4. Access the Application

Once the deployment is complete and the certificate is issued, you can access the application at:

https://dashboard.arcadiasmw.com

If you're using the NodePort configuration, you'll need to specify the port in your browser:

https://dashboard.arcadiasmw.com:30443

Note: If you're using a self-signed certificate or Let's Encrypt staging environment, you might need to accept the security warning in your browser.

## DNS Configuration

For the application to be accessible via dashboard.arcadiasmw.com, you need to configure your DNS to point this domain to your Ubuntu machine's IP address where K3s is installed.

### 1. Find Your Ubuntu Machine's IP Address

```bash
# Check your Ubuntu machine's IP address
ip addr show | grep inet | grep -v '127.0.0.1' | grep -v inet6
```

This will show your machine's IP addresses. Look for the one that's accessible from your network (typically starts with 192.168.x.x, 10.x.x.x, or could be a public IP if your machine is exposed to the internet).

### 2. Configure DNS

You have two options:

#### Option 1: Local Testing with /etc/hosts

For local testing, you can modify your /etc/hosts file (or C:\Windows\System32\drivers\etc\hosts on Windows):

```
<UBUNTU_MACHINE_IP> dashboard.arcadiasmw.com
```

Replace `<UBUNTU_MACHINE_IP>` with your Ubuntu machine's IP address.

#### Option 2: Configure DNS Provider

If you own the domain arcadiasmw.com, add an A record in your DNS provider's settings:

- Type: A
- Name: dashboard
- Value: <UBUNTU_MACHINE_IP>
- TTL: 3600 (or as desired)

### 3. Verify DNS Configuration

```bash
# Verify that the domain resolves to your IP
ping dashboard.arcadiasmw.com
```

## Troubleshooting

### DNS Configuration Issues

If you can't access the application via dashboard.arcadiasmw.com:

1. Verify that your domain is correctly pointing to your Ubuntu machine's IP:
   ```bash
   nslookup dashboard.arcadiasmw.com
   ```

2. Check if the Nginx ingress controller is properly exposed:
   ```bash
   kubectl get svc -n ingress-nginx
   ```
   
3. Ensure your firewall allows traffic on the required ports:
   ```bash
   # Check firewall status
   sudo ufw status
   
   # If using NodePort, allow traffic on ports 30080 and 30443
   sudo ufw allow 30080/tcp
   sudo ufw allow 30443/tcp
   
   # If using standard ports, allow traffic on ports 80 and 443
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### Certificate Issues

If the certificate is not being issued, check the cert-manager logs:

```bash
kubectl logs -n cert-manager -l app=cert-manager
```

### Ingress Issues

Check the Nginx ingress controller logs:

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Cleanup

To remove the deployment:

```bash
kubectl delete -f ingress.yaml
kubectl delete -f certificate.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
