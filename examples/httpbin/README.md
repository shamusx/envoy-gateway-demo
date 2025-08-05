# httpbin Demo Application

httpbin is a simple HTTP request & response service that's perfect for testing EnvoyGateway features.

## Quick Deploy

```bash
# Deploy httpbin application
kubectl apply -f examples/httpbin/deployment.yaml

# Check deployment status
kubectl get pods -n httpbin
kubectl get service -n httpbin
```

## Testing the Service

Once deployed, you can test httpbin directly:

### Port Forward Testing
```bash
# Port forward to httpbin service
kubectl port-forward -n httpbin service/httpbin 8080:8000

# Test in another terminal
curl http://localhost:8080/get
```

### Useful httpbin Endpoints

- `/get` - Returns GET request data
- `/post` - Returns POST request data  
- `/put` - Returns PUT request data
- `/delete` - Returns DELETE request data
- `/headers` - Returns request headers
- `/ip` - Returns client IP
- `/user-agent` - Returns user agent
- `/status/{code}` - Returns given HTTP status code
- `/delay/{seconds}` - Delays response by given seconds
- `/json` - Returns sample JSON data
- `/xml` - Returns sample XML data
- `/html` - Returns sample HTML page
- `/robots.txt` - Returns robots.txt
- `/cache` - Returns cache-related headers
- `/cookies` - Returns cookie data
- `/redirect/{n}` - Redirects n times
- `/basic-auth/{user}/{passwd}` - Basic authentication

### Example Tests
```bash
# Test different HTTP methods
curl -X POST http://localhost:8080/post -d '{"test": "data"}' -H "Content-Type: application/json"
curl -X PUT http://localhost:8080/put -d '{"test": "data"}' -H "Content-Type: application/json"
curl -X DELETE http://localhost:8080/delete

# Test headers
curl http://localhost:8080/headers

# Test status codes
curl http://localhost:8080/status/404
curl http://localhost:8080/status/500

# Test delays (useful for timeout testing)
curl http://localhost:8080/delay/2
```

This httpbin deployment is ready to be used with EnvoyGateway configurations for various use case demonstrations.