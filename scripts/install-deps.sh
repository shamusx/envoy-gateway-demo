#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Installing required dependencies...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install on macOS
install_macos() {
    if ! command_exists brew; then
        echo -e "${RED}❌ Homebrew not found. Please install Homebrew first:${NC}"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    echo -e "${BLUE}📦 Installing dependencies via Homebrew...${NC}"
    
    if ! command_exists kind; then
        echo "Installing kind..."
        brew install kind
    fi
    
    if ! command_exists kubectl; then
        echo "Installing kubectl..."
        brew install kubectl
    fi
    
    if ! command_exists helm; then
        echo "Installing helm..."
        brew install helm
    fi

    if ! command_exists ingress2gateway; then
        echo "Installing ingress2gateway..."
        brew install kubernetes-sigs/ingress2gateway/ingress2gateway
    fi
}

# Function to install on Linux
install_linux() {
    echo -e "${BLUE}📦 Installing dependencies for Linux...${NC}"
    
    # Install kind
    if ! command_exists kind; then
        echo "Installing kind..."
        # For AMD64 / x86_64
        [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        # For ARM64
        [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    # Install kubectl
    if ! command_exists kubectl; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/kubectl
    fi
    
    # Install helm
    if ! command_exists helm; then
        echo "Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    # Install ingress2gateway
    if ! command_exists ingress2gateway; then
        echo "Installing ingress2gateway..."
        # Get latest version
        INGRESS2GATEWAY_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/ingress2gateway/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        # For AMD64 / x86_64
        if [ $(uname -m) = x86_64 ]; then
            curl -Lo ingress2gateway.tar.gz "https://github.com/kubernetes-sigs/ingress2gateway/releases/download/v${INGRESS2GATEWAY_VERSION}/ingress2gateway_${INGRESS2GATEWAY_VERSION}_linux_amd64.tar.gz"
        # For ARM64
        elif [ $(uname -m) = aarch64 ]; then
            curl -Lo ingress2gateway.tar.gz "https://github.com/kubernetes-sigs/ingress2gateway/releases/download/v${INGRESS2GATEWAY_VERSION}/ingress2gateway_${INGRESS2GATEWAY_VERSION}_linux_arm64.tar.gz"
        fi
        tar -xzf ingress2gateway.tar.gz ingress2gateway
        chmod +x ingress2gateway
        sudo mv ingress2gateway /usr/local/bin/ingress2gateway
        rm -f ingress2gateway.tar.gz
    fi
}

# Detect OS and install accordingly
case "$(uname -s)" in
    Darwin*)
        echo -e "${BLUE}🍎 Detected macOS${NC}"
        install_macos
        ;;
    Linux*)
        echo -e "${BLUE}🐧 Detected Linux${NC}"
        install_linux
        ;;
    *)
        echo -e "${RED}❌ Unsupported operating system: $(uname -s)${NC}"
        echo "Please install the following tools manually:"
        echo "- kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        echo "- kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "- helm: https://helm.sh/docs/intro/install/"
        exit 1
        ;;
esac

# Verify installations
echo -e "\n${BLUE}🔍 Verifying installations...${NC}"

if command_exists kind; then
    echo -e "${GREEN}✅ kind: $(kind version)${NC}"
else
    echo -e "${RED}❌ kind not found${NC}"
    exit 1
fi

if command_exists kubectl; then
    echo -e "${GREEN}✅ kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)${NC}"
else
    echo -e "${RED}❌ kubectl not found${NC}"
    exit 1
fi

if command_exists helm; then
    echo -e "${GREEN}✅ helm: $(helm version --short)${NC}"
else
    echo -e "${RED}❌ helm not found${NC}"
    exit 1
fi

if command_exists ingress2gateway; then
    echo -e "${GREEN}✅ ingress2gateway: $(ingress2gateway version 2>/dev/null || echo 'installed')${NC}"
else
    echo -e "${YELLOW}⚠️  ingress2gateway not found. It's optional but recommended for Ingress migration.${NC}"
fi

# Check Docker
if command_exists docker; then
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ docker: $(docker version --format '{{.Client.Version}}')${NC}"
    else
        echo -e "${YELLOW}⚠️  docker found but not running. Please start Docker.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  docker not found. Please install Docker for kind to work.${NC}"
fi

echo -e "\n${GREEN}🎉 Dependencies installation complete!${NC}"