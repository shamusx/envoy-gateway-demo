# EnvoyProxy CR Examples

## Test

### Setup Kind Env

```sh
task setup-all
```

```sh
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg-gateway
  namespace: default
spec:
  gatewayClassName: eg
  infrastructure:
    parametersRef:
      group: gateway.envoyproxy.io
      kind: EnvoyProxy
      name: custom-proxy-name # proxyconfig name
  listeners:
    - name: http
      protocol: HTTP
      port: 80
EOF
```