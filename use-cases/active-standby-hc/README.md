# Active-Standby Health Check Use Case

This use case demonstrates EnvoyGateway's active health checking capabilities with Backend resources in an active-standby configuration.

## Overview

In this scenario:
- **Primary Backend** serves as the active endpoint (httpbingo.org)
- **Standby Backend** serves as the fallback endpoint (httpbin.org)
- **Health Checks** continuously monitor backend availability
- **Automatic Failover** switches traffic when primary backend fails health checks

## Architecture

```mermaid
graph TB
    Client[Client HTTP Request] 
    EG[EnvoyGateway Proxy]
    Primary[Primary Backend httpbingo.org]
    Standby[Standby Backend httpbin.org]
    
    Client -->|HTTP Request| EG
    EG -->|Health Check GET /get| Primary
    EG -->|Health Check GET /get| Standby
    EG -->|Active Traffic| Primary
    EG -.->|Standby Traffic| Standby
    Primary -->|HTTP Response| EG
    Standby -.->|HTTP Response| EG
    EG -->|HTTP Response| Client
    
    subgraph "Kubernetes Cluster"
        subgraph "active-standby-hc namespace"
            subgraph "Backend Resources"
                PrimaryBackend[primary-backend Backend CR]
                StandbyBackend[standby-backend Backend CR]
            end
            
            subgraph "Policies"
                HealthPolicy[active-standby-health-policy BackendTrafficPolicy]
            end
            
            subgraph "Gateway Resources"
                Gateway[active-standby-gateway Gateway]
                HTTPRoute[active-standby-route HTTPRoute]
            end
        end
    end
    
    PrimaryBackend -.->|configures| Primary
    StandbyBackend -.->|configures| Standby
    HealthPolicy -.->|health checks| EG
    Gateway -.->|configures| EG
    HTTPRoute -.->|routes to| PrimaryBackend
    HTTPRoute -.->|routes to| StandbyBackend
    
    classDef gatewayAPI fill:#4fc3f7,stroke:#0277bd,stroke-width:2px,color:#000
    classDef physical fill:#81c784,stroke:#388e3c,stroke-width:2px,color:#000
    classDef backend fill:#ffb74d,stroke:#f57c00,stroke-width:2px,color:#000
    classDef standby fill:#ffcdd2,stroke:#d32f2f,stroke-width:2px,color:#000
    
    class Gateway,HTTPRoute,HealthPolicy gatewayAPI
    class EG physical
    class Primary,PrimaryBackend backend
    class Standby,StandbyBackend standby
```

**Legend:**
- 🔵 **Gateway API Resources** (blue): Gateway, HTTPRoute, BackendTrafficPolicy
- 🟢 **Physical Components** (green): EnvoyGateway proxy
- 🟠 **Active Backend** (orange): Primary backend and Backend CR
- 🔴 **Standby Backend** (red): Standby backend and Backend CR

## Components

- **GatewayClass**: Standard EnvoyGateway class
- **Gateway**: HTTP listener for client traffic
- **HTTPRoute**: Routes traffic to Backend resources
- **Backend Resources**: Primary and standby external endpoints
- **BackendTrafficPolicy**: Configures health checks and load balancing

## Prerequisites

- EnvoyGateway installed (Backend API extension enabled by default)
- Backend API CRDs available

## Files

- `namespace.yaml` - Dedicated namespace for the use case
- `backend.yaml` - Primary and standby Backend resources
- `gateway.yaml` - Gateway and HTTPRoute configuration
- `backend-traffic-policy.yaml` - Health check and traffic policy
- `deploy.sh` - Deployment script
- `test.sh` - Testing script

## Deploy

```bash
cd use-cases/active-standby-hc
./deploy.sh
```

## Test

The deployment script provides comprehensive testing instructions. Key testing points:

- **Hostname**: `active-standby.demo.int`
- **Port**: `18080`
- **Health Check**: GET /get every 5s with 3s timeout

```bash
# Quick test with port-forward
kubectl port-forward -n envoy-gateway-system svc/$GATEWAY_SERVICE 18080:18080 &
curl -H 'Host: active-standby.demo.int' http://localhost:18080/get
```

## Health Check Flow

```mermaid
sequenceDiagram
    participant Client
    participant EnvoyGateway as EnvoyGateway<br/>Proxy
    participant Primary as Primary Backend<br/>httpbingo.org
    participant Standby as Standby Backend<br/>httpbin.org
    
    Note over EnvoyGateway,Standby: Continuous Health Checks
    loop Every 5 seconds
        EnvoyGateway->>Primary: GET /get (Health Check)
        Primary->>EnvoyGateway: HTTP 200 OK (Healthy)
        EnvoyGateway->>Standby: GET /get (Health Check)
        Standby->>EnvoyGateway: HTTP 200 OK (Healthy)
    end
    
    Note over Client,Standby: Normal Traffic Flow (Primary Active)
    Client->>EnvoyGateway: HTTP GET /<br/>Host: active-standby.demo.int
    EnvoyGateway->>Primary: HTTP GET /<br/>(Primary is healthy)
    Primary->>EnvoyGateway: HTTP 200 OK + Response
    EnvoyGateway->>Client: HTTP 200 OK + Response
    
    Note over Primary,Standby: Primary Backend Failure
    EnvoyGateway->>Primary: GET /get (Health Check)
    Primary-->>EnvoyGateway: Connection Failed/Timeout
    Note right of EnvoyGateway: After 3 failed checks,<br/>mark Primary unhealthy
    
    Note over Client,Standby: Failover Traffic Flow (Standby Active)
    Client->>EnvoyGateway: HTTP GET /<br/>Host: active-standby.demo.int
    EnvoyGateway->>Standby: HTTP GET /<br/>(Primary unhealthy, use Standby)
    Standby->>EnvoyGateway: HTTP 200 OK + Response
    EnvoyGateway->>Client: HTTP 200 OK + Response
    
    Note over Primary,Standby: Primary Backend Recovery
    EnvoyGateway->>Primary: GET /get (Health Check)
    Primary->>EnvoyGateway: HTTP 200 OK (Healthy)
    Note right of EnvoyGateway: After 2 successful checks,<br/>mark Primary healthy again
    
    Note over Client,Standby: Traffic Returns to Primary
    Client->>EnvoyGateway: HTTP GET /<br/>Host: active-standby.demo.int
    EnvoyGateway->>Primary: HTTP GET /<br/>(Primary healthy again)
    Primary->>EnvoyGateway: HTTP 200 OK + Response
    EnvoyGateway->>Client: HTTP 200 OK + Response
```

## Key Features Demonstrated

- **Active Health Checking**: Continuous monitoring of backend endpoints
- **Automatic Failover**: Traffic switches to standby when primary fails
- **Backend API**: External endpoints defined as Backend custom resources
- **Configurable Thresholds**: Customizable healthy/unhealthy thresholds
- **Load Balancing**: Round-robin distribution among healthy backends

## Configuration Details

### Health Check Settings
The BackendTrafficPolicy configures:
- **Interval**: 5 seconds between health checks
- **Timeout**: 3 seconds per health check request
- **Unhealthy Threshold**: 3 consecutive failures mark backend unhealthy
- **Healthy Threshold**: 2 consecutive successes mark backend healthy
- **Panic Threshold**: 50% - prevents all backends from being marked unhealthy

### Backend Endpoints
- **Primary Backend**: httpbingo.org (active endpoint)
- **Standby Backend**: httpbin.org (fallback endpoint)
- **Load Balancing**: Round-robin distribution among healthy backends

## Cleanup

```bash
kubectl delete -f .
```