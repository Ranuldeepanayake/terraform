#!/bin/bash
set -euo pipefail

# Install required packages
dnf install -y \
  awscli \
  docker \
  docker-compose \
  git \
  zip \
  unzip \
  curl \
  telnet

# Verify installations
echo "=== Package Versions ==="
aws --version
docker --version
docker-compose --version
git --version
zip --version
unzip -v | head -n 1
curl --version | head -n 1
telnet -h 2>&1 | head -n 1 || echo "telnet installed"

# Enable and start Docker
systemctl enable docker
systemctl start docker

echo "=== All packages installed and Docker started ==="
