#!/usr/bin/env bash
# Ubuntu-specific caller bootstrap appended to the Ubuntu EC2 module user data.
set -euo pipefail

log() {
  printf '[%s] [ec2-ubuntu-bootstrap] %s\n' "$(date --iso-8601=seconds)" "$*"
}

log "Installing required Ubuntu packages"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  awscli \
  docker.io \
  docker-compose-v2 \
  git \
  zip \
  unzip \
  curl \
  telnet \
  python3-pip

log "Enabling and starting Docker"
systemctl enable --now docker

# Install Buildx as a system-wide Docker CLI plugin when it is not already
# available. The pinned version keeps bootstrap behavior reproducible.
if ! docker buildx version >/dev/null 2>&1; then
  buildx_version="v0.17.1"
  case "$(uname -m)" in
    x86_64) buildx_arch="amd64" ;;
    aarch64) buildx_arch="arm64" ;;
    *) log "Unsupported CPU architecture for Docker Buildx: $(uname -m)" >&2; exit 1 ;;
  esac

  buildx_plugin_dir="/usr/local/lib/docker/cli-plugins"
  install -d -m 0755 "$buildx_plugin_dir"
  curl --fail --location --retry 3 \
    "https://github.com/docker/buildx/releases/download/${buildx_version}/buildx-${buildx_version}.linux-${buildx_arch}" \
    --output "$buildx_plugin_dir/docker-buildx"
  chmod 0755 "$buildx_plugin_dir/docker-buildx"
fi

log "Package versions"
aws --version
docker --version
docker compose version
docker buildx version
git --version
zip --version | head -n 1
unzip -v | head -n 1
curl --version | head -n 1

log "Ubuntu EC2 bootstrap installation complete"
