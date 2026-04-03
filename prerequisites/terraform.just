# prerequisites/terraform.just — add HashiCorp apt repo (Ubuntu only)

prereq-terraform:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ "{{OS}}" != "Linux" ] || [ "{{DISTRO}}" != "ubuntu" ]; then
        exit 0
    fi

    if [ -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
        echo "  skip   HashiCorp apt repo (already added)"
        exit 0
    fi

    echo "Adding HashiCorp apt repo..."
    sudo apt-get install -y wget gpg lsb-release
    wget -qO- https://apt.releases.hashicorp.com/gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -y
    echo "  done   HashiCorp apt repo"
