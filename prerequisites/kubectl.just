# prerequisites/kubectl.just — add Kubernetes apt repo (Ubuntu only)

prereq-kubectl:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ "{{OS}}" != "Linux" ] || [ "{{DISTRO}}" != "ubuntu" ]; then
        exit 0
    fi

    if [ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
        echo "  skip   Kubernetes apt repo (already added)"
        exit 0
    fi

    echo "Adding Kubernetes apt repo..."
    sudo apt-get install -y curl gpg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
        | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -y
    echo "  done   Kubernetes apt repo"
