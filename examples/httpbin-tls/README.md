# httpbin with TLS Support

This example demonstrates httpbin with HTTPS support using certificates provisioned by cert-manager.

## Features

- **HTTPS enabled**: httpbin serves on HTTPS using cert-manager certificates
- **Self-signed certificates**: Uses ClusterIssuer for demo purposes
- **Certificate mounting**: Certificates mounted as volumes from Kubernetes secrets
- **Environment variables**: Configures httpbin with cert/key file locations

## Prerequisites

- cert-manager installed and running
- EnvoyGateway sandbox setup completed

## Deploy

```bash
# Deploy httpbin with TLS support
kubectl apply -f examples/httpbin-tls/deployment.yaml

# Check deployment status
kubectl get pods -n httpbin-tls
kubectl get certificate -n httpbin-tls
kubectl get secret -n httpbin-tls
```

## Verify Certificate

```bash
# Check certificate status
kubectl describe certificate httpbin-tls-cert -n httpbin-tls

# View certificate details
kubectl get secret httpbin-tls-secret -n httpbin-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

## Testing

### Port Forward Testing
```bash
# Port forward to httpbin-tls service
kubectl port-forward -n httpbin-tls service/httpbin-tls 8443:8443

# Test HTTPS endpoint (ignore self-signed cert warnings)
curl -k https://localhost:8443/get

# Test with certificate details
curl -k -v https://localhost:8443/get
```

### Certificate Information
```bash
# Get certificate info from the service
curl -k https://localhost:8443/get | jq '.headers'

# Check TLS connection details
openssl s_client -connect localhost:8443 -servername localhost < /dev/null
```

## Use Cases

This TLS-enabled httpbin is perfect for:

- **Backend TLS**: Demonstrating EnvoyGateway to backend TLS connections
- **mTLS scenarios**: Can be extended to require client certificates
- **Certificate rotation**: Testing cert-manager certificate renewal
- **TLS policy testing**: Various TLS configuration scenarios

## Configuration Details

- **Service Port**: 8443 (HTTPS)
- **Container Port**: 8080 (httpbin listens on 8080 but serves HTTPS)
- **Certificate Path**: `/etc/certs/tls.crt`
- **Private Key Path**: `/etc/certs/tls.key`
- **DNS Names**: Includes service DNS names and localhost for testing

## Cleanup

```bash
kubectl delete -f examples/httpbin-tls/deployment.yaml
```